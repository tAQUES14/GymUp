<?php

namespace App\Services;

use App\Models\GymOpenDay;
use App\Models\User;
use App\Models\UserWorkoutPlan;
use App\Models\WorkoutPlanDay;
use App\Models\WorkoutSession;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;


class StreakService
{

    public function getStreakState(User $user): array
    {
        $user->refresh();

        return $this->buildState($user);
    }

    // só avança o streak uma vez por dia
    public function processWorkoutForDailyStreak(User $user): array
    {
        $user->refresh();
        $today               = now()->toDateString();
        $streakJustIncreased = false;

        $lastDate = $user->last_workout_date instanceof Carbon
            ? $user->last_workout_date->toDateString()
            : (string) ($user->last_workout_date ?? '');

        // Idempotente: só processa uma vez por dia
        if ($lastDate !== $today && $this->isObligatoryDay($user, now())) {
            // Verifica dias obrigatórios perdidos antes de avançar
            $this->checkAndBreakIfNeeded($user, now());
            $user->refresh();

            $newStreak            = ((int) $user->current_streak) + 1;
            $user->current_streak = $newStreak;
            $user->best_streak    = max($newStreak, (int) $user->best_streak);
            $user->last_workout_date = $today;
            $user->save();
            $user->refresh();
            $streakJustIncreased = true;
        }

        return array_merge(
            $this->buildState($user),
            ['streak_just_increased' => $streakJustIncreased]
        );
    }

    public function processWorkoutForWeeklyStreak(User $user): array
    {
        return $this->processWorkoutForDailyStreak($user);
    }

    public function isObligatoryDay(User $user, Carbon $date): bool
    {
        $dow = $date->dayOfWeek; // Carbon: 0=Dom, 6=Sáb
        return $this->isGymOpenOn($user, $dow) && $this->planHasWorkoutOn($user, $dow);
    }


    private function checkAndBreakIfNeeded(User $user, Carbon $upTo): void
    {
        if (! $user->last_workout_date) {
            return;
        }

        $last           = Carbon::parse($user->last_workout_date)->startOfDay();
        $upToStartOfDay = $upTo->copy()->startOfDay();

        $check = $last->copy()->addDay();
        while ($check->lt($upToStartOfDay)) {
            if ($this->isObligatoryDay($user, $check)) {
                $user->current_streak = 0;
                $user->save();
                return;
            }
            $check->addDay();
        }
    }


    private function hasPlan(User $user): bool
    {
        return UserWorkoutPlan::active()->where('user_id', $user->id)->exists();
    }

    // sem plano ativo → qualquer dia que academia está aberta conta; dia não configurado no plano = descanso implícito → false
    private function planHasWorkoutOn(User $user, int $dow): bool
    {
        $userPlan = UserWorkoutPlan::active()->where('user_id', $user->id)->first();

        if (! $userPlan) {
            return true;
        }

        $day = WorkoutPlanDay::where('plan_id', $userPlan->plan_id)
            ->where('day_of_week', $dow)
            ->first();

        // Sem dia configurado = descanso implícito
        if (! $day) {
            return false;
        }

        return ! $day->rest_day;
    }

    private function isGymOpenOn(User $user, int $dow): bool
    {
        if (! $user->gym_id) {
            return true;
        }

        try {
            $record = GymOpenDay::where('gym_id', $user->gym_id)
                ->where('day_of_week', $dow)
                ->first();

            return $record === null || $record->is_open;
        } catch (\Exception $e) {
            Log::warning('StreakService: falha ao consultar gym_open_days', [
                'gym_id' => $user->gym_id,
                'dow'    => $dow,
                'error'  => $e->getMessage(),
            ]);
            return true;
        }
    }


    private function countWorkoutsThisWeek(User $user): int
    {
        $weekStart = Carbon::now()->startOfWeek(Carbon::SUNDAY);
        $weekEnd   = $weekStart->copy()->addDays(6)->endOfDay();

        return WorkoutSession::where('user_id', $user->id)
            ->where('points_granted', true)
            ->whereBetween('finished_at', [$weekStart, $weekEnd])
            ->get(['finished_at'])
            ->map(fn ($s) => $s->finished_at->toDateString())
            ->unique()
            ->count();
    }

    private function getWeeklyGoal(User $user): int
    {
        $userPlan = UserWorkoutPlan::active()->where('user_id', $user->id)->first();

        if ($userPlan) {
            $count = WorkoutPlanDay::where('plan_id', $userPlan->plan_id)
                ->where('rest_day', false)
                ->whereNotNull('day_of_week')
                ->count();

            if ($count > 0) {
                return $count;
            }
        }

        return 3; // padrão quando sem plano
    }

    private function buildState(User $user): array
    {
        $goal      = $this->getWeeklyGoal($user);
        $done      = $this->countWorkoutsThisWeek($user);
        $remaining = max(0, $goal - $done);

        return [
            'streak'                       => (int) ($user->current_streak ?? 0),
            'best_streak'                  => (int) ($user->best_streak ?? 0),
            'remaining_workouts_this_week' => $remaining,
            'workouts_done_this_week'      => $done,
            'weekly_goal'                  => $goal,
        ];
    }
}
