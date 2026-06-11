<?php

namespace App\Services;

use App\Models\WorkoutSession;
use App\Models\User;
use Illuminate\Support\Facades\DB;


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

    public function handle(
        WorkoutSession $session,
        User           $user,
        int            $completionPercent,
        int            $durationSeconds,
        bool           $confirmPartial,
        bool           $hasCheckinToday,
    ): array {
        // 1. validação
        $validation = $this->validator->validate(
            $completionPercent,
            $durationSeconds,
            $hasCheckinToday,
            $confirmPartial
        );

        if ($validation['status'] === WorkoutValidationService::STATUS_PARTIAL_CONFIRM) {
            $streakState = $this->streak->getStreakState($user);
            return $this->buildResponse($validation, 0, false, $streakState, null, [], null, [], 0, $session);
        }

        $isValid = $validation['status'] === WorkoutValidationService::STATUS_VALID;

        // 2. contexto do plano
        $isOnPlan        = $this->planService->getPlanDayContext($user, now()) === 'workout_day';
        $isObligatoryDay = $this->streak->isObligatoryDay($user, now());

        // 3. elegibilidade — 1 concessão por dia, streak só em dias obrigatórios
        $alreadyGrantedToday = WorkoutSession::hasGrantedPointsToday($user->id);
        $countsForPoints     = $isValid && ! $session->points_granted && ! $alreadyGrantedToday;
        $countsForStreak     = $countsForPoints && $isObligatoryDay;

        // 4. finalizar sessão e conceder pontos
        $pointsGenerated = 0;

        if ($countsForPoints) {
            $multiplier = (float) ($validation['points_multiplier'] ?? 1.0);
            $basePoints = (int) floor(config('workout.daily_points', 10) * $multiplier);

            DB::transaction(function () use (
                $session,
                $user,
                $basePoints,
                $countsForStreak,
                &$pointsGenerated,
            ) {
                $locked = WorkoutSession::where('id', $session->id)->lockForUpdate()->first();

                if ($locked && ! $locked->points_granted) {
                    $locked->update([
                        'finished_at'       => now(),
                        'is_valid'          => true,
                        'counts_for_points' => true,
                        'counts_for_streak' => $countsForStreak,
                        'points_granted'    => true,
                        'points_granted_at' => now(),
                    ]);

                    $this->points->earnPoints(
                        $user,
                        $basePoints,
                        'Treino concluído',
                        'workout',
                        $session->id
                    );

                    $pointsGenerated = $basePoints;
                }
            });

            $user->refresh();
        } else {
            $session->update([
                'finished_at'       => now(),
                'is_valid'          => $isValid,
                'counts_for_points' => false,
                'counts_for_streak' => false,
            ]);
        }

        $wasGranted = $pointsGenerated > 0;

        // 5. streak
        $streakState = $wasGranted
            ? $this->streak->processWorkoutForDailyStreak($user)
            : $this->streak->getStreakState($user);

        // 6. pós-concessão: desafios, PR, progresso
        if ($wasGranted && ($streakState['streak_just_increased'] ?? false)) {
            $streakBonus = $this->points->grantStreakMilestoneBonus(
                $user,
                (int) $streakState['streak'],
                $session->id
            );

            if ($streakBonus > 0) {
                $pointsGenerated += $streakBonus;
                $user->refresh();
            }
        }

        $challengeProgress          = null;
        $personalChallengesProgress = [];
        $progressMessage            = null;
        $prMessages                 = [];
        $workoutVolume              = 0;

        if ($wasGranted) {
            $challengeResults = $this->challenges->processValidWorkout($user, $session->fresh());

            if ($communityResult = $challengeResults['community'] ?? null) {
                $progressData      = $this->challenges->getChallengeData($communityResult['challenge'], $user);
                $challengeProgress = array_merge($progressData, [
                    'simple_goal_just_completed' => $communityResult['simple_goal_just_completed'],
                ]);
            }

            foreach ($challengeResults['personal'] ?? [] as $personalResult) {
                $progressData        = $this->challenges->getChallengeData($personalResult['challenge'], $user);
                $personalChallengesProgress[] = array_merge($progressData, [
                    'simple_goal_just_completed' => $personalResult['simple_goal_just_completed'],
                ]);
            }

            $prBonus = $this->points->grantPrBonus($user, $session->id);
            if ($prBonus > 0) {
                $pointsGenerated += $prBonus;
                $user->refresh();
            }

            $progressMessage = $this->setService->detectProgress($user->id, $session->id);
            $prMessages      = $this->progressService->detectPRs($user->id, $session->id);
            $workoutVolume   = (int) round($this->progressService->getSessionVolume($session->id));
        }

        return $this->buildResponse(
            $validation,
            $pointsGenerated,
            $isOnPlan,
            $streakState,
            $challengeProgress,
            $personalChallengesProgress,
            $progressMessage,
            $prMessages,
            $workoutVolume,
            $session->fresh(),
        );
    }

    private function buildResponse(
        array          $validation,
        int            $pointsGenerated,
        bool           $isOnPlan,
        array          $streakState,
        ?array         $challengeProgress,
        array          $personalChallengesProgress,
        ?string        $progressMessage,
        array          $prMessages,
        int            $workoutVolume,
        WorkoutSession $session,
    ): array {
        return [
            'status'                        => $validation['status'],
            'message'                       => $validation['message'],
            'points_generated'              => $pointsGenerated,
            'is_on_plan'                    => $isOnPlan,
            'streak_current'                => $streakState['streak'],
            'best_streak'                   => $streakState['best_streak'],
            'streak_just_increased'         => $streakState['streak_just_increased'] ?? false,
            'remaining_workouts_this_week'  => $streakState['remaining_workouts_this_week'],
            'challenge_progress'            => $challengeProgress,
            'personal_challenges_progress'  => $personalChallengesProgress,
            'progress_message'              => $progressMessage,
            'pr_messages'                   => $prMessages,
            'workout_volume'                => $workoutVolume,
            'session'                       => $session,
        ];
    }
}
