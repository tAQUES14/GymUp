<?php

namespace App\Services;

use App\Models\WorkoutSession;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Orchestrates the full workout-finish flow.
 *
 * Responsibilities (in order):
 *   1. Validate the workout (time, progress, check-in)
 *   2. Determine eligibility: is this the first valid workout of the day?
 *   3. Finish the session and grant points atomically (when eligible)
 *   4. Update streak
 *   5. Run post-grant hooks: plan advancement, challenges, bonuses, analytics
 *
 * The controller only handles HTTP concerns (request parsing, response building).
 * All domain logic lives here.
 */
class WorkoutFinishService
{
    public function __construct(
        private readonly WorkoutValidationService $validator,
        private readonly PointService             $points,
        private readonly StreakService            $streak,
        private readonly WorkoutPlanService       $planService,
        private readonly ChallengeService         $challenges,
        private readonly WorkoutSetService        $setService,
        private readonly ExerciseProgressService  $progressService,
    ) {}

    /**
     * Runs the finish flow and returns the full response payload.
     *
     * The 'session' key in the returned array is a refreshed Eloquent model;
     * the controller is responsible for formatting it for the API response.
     */
    public function handle(
        WorkoutSession $session,
        User           $user,
        int            $completionPercent,
        int            $durationSeconds,
        bool           $confirmPartial,
        bool           $hasCheckinToday,
    ): array {
        // ── Step 1: Validate ───────────────────────────────────────────────────
        $validation = $this->validator->validate(
            $completionPercent,
            $durationSeconds,
            $hasCheckinToday,
            $confirmPartial
        );

        // Partial confirmation required: pause without finishing the session.
        // The client will re-submit with confirm_partial = true.
        if ($validation['status'] === WorkoutValidationService::STATUS_PARTIAL_CONFIRM) {
            $streakState = $this->streak->getStreakState($user);
            return $this->buildResponse($validation, 0, $streakState, false, null, null, [], 0, $session);
        }

        $isValid = $validation['status'] === WorkoutValidationService::STATUS_VALID;

        // ── Step 2: Determine eligibility ──────────────────────────────────────
        //
        // Rule: only the FIRST valid workout of the day earns points and counts
        // for streak. All subsequent valid workouts are recorded as valid
        // (is_valid = true) but counts_for_points / counts_for_streak = false.
        //
        // The check uses points_granted to detect a prior qualifying session.
        // hasGrantedPointsToday uses finished_at so a session that started
        // yesterday but finished today is attributed to today (correct).
        $alreadyGrantedToday = WorkoutSession::hasGrantedPointsToday($user->id);
        $countsForPoints     = $isValid && !$session->points_granted && !$alreadyGrantedToday;
        $countsForStreak     = $countsForPoints; // same rule; separate field for future flexibility

        // ── Step 3: Finish session + grant points (atomically when eligible) ───
        $pointsGenerated = 0;

        if ($countsForPoints) {
            $basePoints      = (int) config('workout.daily_points', 10);
            $potentialPoints = (int) round($basePoints * $validation['points_multiplier']);

            DB::transaction(function () use ($session, $user, $potentialPoints, &$pointsGenerated) {
                // Lock the row to prevent a race condition where two concurrent
                // requests both see hasGrantedPointsToday = false and both grant points.
                $locked = WorkoutSession::where('id', $session->id)->lockForUpdate()->first();

                if ($locked && !$locked->points_granted) {
                    $locked->update([
                        'finished_at'       => now(),
                        'is_valid'          => true,
                        'counts_for_points' => true,
                        'counts_for_streak' => true,
                        'points_granted'    => true,       // kept for backward compatibility
                        'points_granted_at' => now(),
                    ]);

                    $this->points->earnPoints(
                        $user,
                        $potentialPoints,
                        'Treino concluído',
                        'workout',
                        $session->id
                    );

                    $pointsGenerated = $potentialPoints;
                }
            });

            $user->refresh();
        } else {
            // Finish without points: either invalid, or a valid-but-second workout of the day.
            // Both cases are recorded with their correct is_valid value so the
            // history can distinguish them from truly invalid sessions.
            $session->update([
                'finished_at'       => now(),
                'is_valid'          => $isValid,
                'counts_for_points' => false,
                'counts_for_streak' => false,
            ]);
        }

        $wasGranted = $pointsGenerated > 0;

        // ── Step 4: Update streak ──────────────────────────────────────────────
        //
        // processWorkoutForDailyStreak increments the daily streak and updates
        // weekly progress. Called only when this session is the qualifying one.
        $streakState = $wasGranted
            ? $this->streak->processWorkoutForDailyStreak($user)
            : $this->streak->getStreakState($user);

        $weeklyGoalJustCompleted = $wasGranted && ($streakState['weekly_goal_just_completed'] ?? false);

        // ── Step 5: Post-grant hooks ───────────────────────────────────────────
        //
        // Everything below only runs for the qualifying workout of the day.
        // A second valid workout does NOT advance the plan, affect challenges,
        // or earn bonuses — it is simply recorded in history.
        $challengeProgress = null;
        $progressMessage   = null;
        $prMessages        = [];
        $workoutVolume     = 0;

        if ($wasGranted) {
            // Advance the student's sequential workout plan by one day
            $this->planService->advancePlanAfterWorkout($user);

            // Challenge progress (e.g. "complete 5 workouts this week")
            $challengeResult = $this->challenges->processValidWorkout($user, $session->fresh());
            if ($challengeResult) {
                $progressData      = $this->challenges->getChallengeData($challengeResult['challenge'], $user);
                $challengeProgress = array_merge($progressData, [
                    'simple_goal_just_completed' => $challengeResult['simple_goal_just_completed'],
                ]);
            }

            // Streak bonus: fires only when the weekly goal was just completed
            if ($weeklyGoalJustCompleted) {
                $streakBonus = $this->points->grantStreakBonus($user, $streakState['streak'], $session->id);
                if ($streakBonus > 0) {
                    $pointsGenerated += $streakBonus;
                    $user->refresh();
                }
            }

            // PR bonus: fires whenever a personal record was beaten today
            $prBonus = $this->points->grantPrBonus($user, $session->id);
            if ($prBonus > 0) {
                $pointsGenerated += $prBonus;
                $user->refresh();
            }

            // Performance analytics (motivational messages, not critical)
            $progressMessage = $this->setService->detectProgress($user->id, $session->id);
            $prMessages      = $this->progressService->detectPRs($user->id, $session->id);
            $workoutVolume   = (int) round($this->progressService->getSessionVolume($session->id));
        }

        return $this->buildResponse(
            $validation,
            $pointsGenerated,
            $streakState,
            $weeklyGoalJustCompleted,
            $challengeProgress,
            $progressMessage,
            $prMessages,
            $workoutVolume,
            $session->fresh(),
        );
    }

    /**
     * Assembles the response array returned to the controller.
     *
     * Kept private so the shape of the internal result is defined in one place.
     * The 'session' value is a raw Eloquent model; the controller formats it.
     */
    private function buildResponse(
        array          $validation,
        int            $pointsGenerated,
        array          $streakState,
        bool           $weeklyGoalJustCompleted,
        ?array         $challengeProgress,
        ?string        $progressMessage,
        array          $prMessages,
        int            $workoutVolume,
        WorkoutSession $session,
    ): array {
        return [
            'status'                       => $validation['status'],
            'message'                      => $validation['message'],
            'points_generated'             => $pointsGenerated,
            'streak_current'               => $streakState['streak'],
            'best_streak'                  => $streakState['best_streak'],
            'streak_just_increased'        => $streakState['streak_just_increased'] ?? false,
            'weekly_goal_just_completed'   => $weeklyGoalJustCompleted,
            'remaining_workouts_this_week' => $streakState['remaining_workouts_this_week'],
            'challenge_progress'           => $challengeProgress,
            'progress_message'             => $progressMessage,
            'pr_messages'                  => $prMessages,
            'workout_volume'               => $workoutVolume,
            'session'                      => $session,
        ];
    }
}
