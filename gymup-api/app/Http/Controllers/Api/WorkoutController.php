<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Models\WorkoutSession;
use App\Services\ChallengeService;
use App\Services\PointService;
use App\Services\StreakService;
use App\Services\WorkoutValidationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WorkoutController extends Controller
{
    /**
     * POST /api/workout/start
     *
     * Starts a new workout session for the authenticated user.
     * Idempotent: if an active session already exists, returns it.
     */
    public function start(Request $request)
    {
        $user = $request->user();

        $timeoutHours = (int) config('workout.session_timeout_hours', 4);

        $session = DB::transaction(function () use ($user, $timeoutHours) {
            $active = WorkoutSession::where('user_id', $user->id)
                ->whereNull('finished_at')
                ->lockForUpdate()
                ->first();

            if ($active) {
                // Auto-expire sessions older than the configured timeout
                if ($active->started_at->diffInHours(now()) >= $timeoutHours) {
                    $active->update(['finished_at' => now()]);
                } else {
                    return $active;
                }
            }

            return WorkoutSession::create([
                'user_id'        => $user->id,
                'gym_id'         => $user->gym_id,
                'started_at'     => now(),
                'progress'       => 0,
                'points_granted' => false,
            ]);
        });

        $isExisting = !$session->wasRecentlyCreated;

        return response()->json([
            'message'     => $isExisting
                ? 'Sessão de treino já ativa.'
                : 'Sessão de treino iniciada.',
            'session'     => $this->formatSession($session),
            'is_existing' => $isExisting,
        ], $isExisting ? 200 : 201);
    }

    /**
     * POST /api/workout/progress
     *
     * Updates the progress (0–100) of the active session.
     */
    public function updateProgress(Request $request)
    {
        $request->validate([
            'progress' => 'required|integer|between:0,100',
        ]);

        $user = $request->user();

        $session = WorkoutSession::where('user_id', $user->id)
            ->whereNull('finished_at')
            ->first();

        if (!$session) {
            return response()->json([
                'message' => 'Nenhuma sessão de treino ativa.',
            ], 404);
        }

        Log::info('workout.progress', [
            'user_id'    => $user->id,
            'session_id' => $session->id,
            'progress'   => $request->progress,
            'elapsed_s'  => (int) $session->started_at->diffInSeconds(now()),
        ]);

        $session->update(['progress' => $request->progress]);

        return response()->json([
            'message' => 'Progresso atualizado.',
            'session' => $this->formatSession($session->fresh()),
        ]);
    }

    /**
     * POST /api/workout/finish
     *
     * Central endpoint to finish a workout session with full validation.
     *
     * Input:
     *   - completion_percent (int, 0-100) — optional, defaults to session progress
     *   - duration_seconds (int) — optional, defaults to elapsed time
     *   - confirm_partial (bool) — whether to confirm a partial workout (70-74%)
     *
     * Output:
     *   - status: VALID | PARTIAL_CONFIRM | INVALID
     *   - message: human-readable message
     *   - points_generated: int
     *   - streak_current: int
     *   - total_points: int
     *   - checkin_validated: bool
     */
    public function finish(
        Request                   $request,
        PointService              $pointService,
        WorkoutValidationService  $validationService,
        StreakService              $streakService,
        ?int                      $id = null
    ) {
        $request->validate([
            'completion_percent' => 'nullable|integer|between:0,100',
            'duration_seconds'   => 'nullable|integer|min:0',
            'confirm_partial'    => 'nullable|boolean',
        ]);

        $user = $request->user();

        $query = WorkoutSession::where('user_id', $user->id)
            ->whereNull('finished_at');

        if ($id !== null) {
            $query->where('id', $id);
        }

        $session = $query->first();

        if (!$session) {
            return response()->json([
                'message' => 'Nenhuma sessão de treino ativa.',
            ], 404);
        }

        // Use provided values or fall back to session data
        $completionPercent = $request->input('completion_percent', $session->progress);
        $durationSeconds   = $request->input('duration_seconds',
            (int) $session->started_at->diffInSeconds(now())
        );
        $confirmPartial = (bool) $request->input('confirm_partial', false);

        // Update session progress with the final value
        $session->update(['progress' => $completionPercent]);

        // Check if user has a check-in today
        $hasCheckinToday = Checkin::where('user_id', $user->id)
            ->where('checkin_date', now()->toDateString())
            ->exists();

        // Validate workout
        $result = $validationService->validate(
            $completionPercent,
            $durationSeconds,
            $hasCheckinToday,
            $confirmPartial
        );

        // If partial needs confirmation, DON'T finish the session yet
        if ($result['status'] === WorkoutValidationService::STATUS_PARTIAL_CONFIRM) {
            $streakState = $streakService->getStreakState($user);

            return response()->json([
                'status'                      => $result['status'],
                'message'                     => $result['message'],
                'points_generated'            => 0,
                'streak_current'              => $streakState['streak'],
                'total_points'                => (int) $user->points_balance,
                'checkin_validated'           => $hasCheckinToday,
                'weekly_goal_just_completed'  => false,
                'remaining_workouts_this_week' => $streakState['remaining_workouts_this_week'],
                'session'                     => $this->formatSession($session->fresh()),
            ], 200);
        }

        // Grant points and finish the session atomically when eligible.
        // $pointsGenerated is only set to > 0 if points were actually credited.
        // $sessionFinished tracks whether finished_at was set inside the transaction.
        $pointsGenerated = 0;
        $sessionFinished = false;

        if ($result['status'] === WorkoutValidationService::STATUS_VALID) {
            $basePoints      = (int) config('workout.daily_points', 10);
            $potentialPoints = (int) round($basePoints * $result['points_multiplier']);

            if ($potentialPoints > 0 && !$session->points_granted && !WorkoutSession::hasGrantedPointsToday($user->id)) {
                DB::transaction(function () use ($session, $user, $pointService, $potentialPoints, &$pointsGenerated, &$sessionFinished) {
                    $locked = WorkoutSession::where('id', $session->id)
                        ->lockForUpdate()
                        ->first();

                    if ($locked && !$locked->points_granted) {
                        // BUG 5 fix: finish_at set atomically with points grant
                        $locked->update([
                            'points_granted'    => true,
                            'points_granted_at' => now(),
                            'finished_at'       => now(),
                        ]);

                        $pointService->earnPoints(
                            $user,
                            $potentialPoints,
                            'Treino concluído',
                            'workout',
                            $session->id
                        );

                        // BUG 3 fix: only reflect actual points granted
                        $pointsGenerated = $potentialPoints;
                        $sessionFinished = true;
                    }
                });

                $user->refresh();
            }
        }

        // Finish the session if not already done inside the transaction above
        if (!$sessionFinished) {
            $session->update(['finished_at' => now()]);
        }

        // Update streak state and detect if weekly goal was just met
        if ($sessionFinished) {
            $streakState             = $streakService->processWorkoutForWeeklyStreak($user);
            $weeklyGoalJustCompleted = $streakState['weekly_goal_just_completed'];
        } else {
            $streakState             = $streakService->getStreakState($user);
            $weeklyGoalJustCompleted = false;
        }

        // Atualiza progresso nos desafios da academia após treino válido
        $challengeService  = app(ChallengeService::class);
        $challengeResult   = null;

        if ($sessionFinished) {
            $challengeResult = $challengeService->processValidWorkout($user, $session->fresh());
        }

        $challengeProgress = null;
        if ($challengeResult) {
            $progressData      = $challengeService->getChallengeData($challengeResult['challenge'], $user);
            $challengeProgress = array_merge($progressData, [
                'simple_goal_just_completed' => $challengeResult['simple_goal_just_completed'],
            ]);
        }

        // BUG 8 fix: streak bonus only when weekly goal just completed; PR bonus whenever points earned.
        if ($sessionFinished) {
            if ($weeklyGoalJustCompleted) {
                $streakBonus = $pointService->grantStreakBonus($user, $streakState['streak'], $session->id);
                if ($streakBonus > 0) {
                    $pointsGenerated += $streakBonus;
                    $user->refresh();
                }
            }

            $prBonus = $pointService->grantPrBonus($user, $session->id);
            if ($prBonus > 0) {
                $pointsGenerated += $prBonus;
                $user->refresh();
            }
        }

        return response()->json([
            'status'                       => $result['status'],
            'message'                      => $result['message'],
            'points_generated'             => $pointsGenerated,
            'streak_current'               => $streakState['streak'],
            'total_points'                 => (int) $user->points_balance,
            'checkin_validated'            => $hasCheckinToday,
            'weekly_goal_just_completed'   => $weeklyGoalJustCompleted,
            'remaining_workouts_this_week' => $streakState['remaining_workouts_this_week'],
            'challenge_progress'           => $challengeProgress,
            'session'                      => $this->formatSession($session->fresh()),
        ]);
    }

    /**
     * GET /api/workout/status
     */
    public function status(Request $request)
    {
        $session = WorkoutSession::where('user_id', $request->user()->id)
            ->latest('started_at')
            ->first();

        return response()->json([
            'session' => $session ? $this->formatSession($session) : null,
        ]);
    }

    /**
     * Formats a WorkoutSession into the standard API response array.
     */
    private function formatSession(WorkoutSession $session): array
    {
        $endpoint     = $session->finished_at ?? now();
        $dailyGranted = WorkoutSession::hasGrantedPointsToday($session->user_id);

        return [
            'id'                           => $session->id,
            'started_at'                   => $session->started_at->toIso8601String(),
            'finished_at'                  => $session->finished_at?->toIso8601String(),
            'is_active'                    => $session->isActive(),
            'progress'                     => $session->progress,
            'elapsed_seconds'              => (int) $session->started_at->diffInSeconds($endpoint),
            'points_granted'               => $session->points_granted,
            'points_granted_at'            => $session->points_granted_at?->toIso8601String(),
            'meets_conditions'             => $session->meetsPointsConditions(),
            'can_earn_points'              => !$session->points_granted && !$dailyGranted,
            'min_minutes'                  => (int) config('workout.min_minutes', 10),
            'daily_points_already_granted' => $dailyGranted,
            'requirements'                 => [
                'min_minutes'          => (int) config('workout.min_minutes'),
                'min_progress_valid'   => (int) config('workout.min_progress_valid'),
                'min_progress_partial' => (int) config('workout.min_progress_partial'),
            ],
        ];
    }
}
