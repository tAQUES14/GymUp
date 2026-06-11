<?php

namespace App\Services;

use App\Models\ExerciseWeight;
use App\Models\PointTransaction;
use App\Models\User;

class PointService
{
    // category: workout|streak|pr
    public function earnPoints(
        User    $user,
        int     $points,
        string  $description,
        string  $category = 'workout',
        ?int    $referenceId = null
    ): void {
        if ($points <= 0) {
            return;
        }

        PointTransaction::create([
            'user_id'      => $user->id,
            'gym_id'       => $user->gym_id,
            'type'         => 'earn',
            'category'     => $category,
            'points'       => $points,
            'description'  => $description,
            'reference_id' => $referenceId,
        ]);

        $user->increment('points_balance', $points);
    }

    public function spendPoints(
        User    $user,
        int     $points,
        string  $description,
        string  $category = 'redemption',
        ?int    $referenceId = null
    ): void {
        if ($user->points_balance < $points) {
            throw new \Exception('Saldo insuficiente.');
        }

        PointTransaction::create([
            'user_id'      => $user->id,
            'gym_id'       => $user->gym_id,
            'type'         => 'spend',
            'category'     => $category,
            'points'       => $points,
            'description'  => $description,
            'reference_id' => $referenceId,
        ]);

        $user->decrement('points_balance', $points);
    }

    // idempotente: sem-op se já concedeu hoje
    public function grantStreakBonus(User $user, int $streak, int $referenceId): int
    {
        if ($streak < 2) {
            return 0;
        }

        $alreadyGranted = PointTransaction::where('user_id', $user->id)
            ->where('type', 'earn')
            ->where('category', 'streak')
            ->whereDate('created_at', now()->toDateString())
            ->exists();

        if ($alreadyGranted) {
            return 0;
        }

        $bonus = (int) config('workout.streak_bonus', 5);
        $this->earnPoints($user, $bonus, "Bônus de streak ({$streak} semanas)", 'streak', $referenceId);

        return $bonus;
    }

    // idempotente: sem-op se o marco de streak ja foi concedido antes
    public function grantStreakMilestoneBonus(User $user, int $streakDays, int $referenceId): int
    {
        $milestones = collect(config('workout.streak_bonus_milestones', []))
            ->mapWithKeys(fn ($points, $days) => [(int) $days => (int) $points]);

        $bonus = (int) ($milestones[$streakDays] ?? 0);
        if ($bonus <= 0) {
            return 0;
        }

        $description = "Bônus de streak de {$streakDays} dias";

        $alreadyGranted = PointTransaction::where('user_id', $user->id)
            ->where('type', 'earn')
            ->where('category', 'streak')
            ->where('description', $description)
            ->exists();

        if ($alreadyGranted) {
            return 0;
        }

        $this->earnPoints($user, $bonus, $description, 'streak', $referenceId);

        return $bonus;
    }

    public function grantPrBonus(User $user, int $referenceId): int
    {
        $historicalBest = ExerciseWeight::where('user_id', $user->id)
            ->whereDate('created_at', '<', now()->toDateString())
            ->selectRaw('MAX(weight * (1 + reps / 30.0)) as best')
            ->value('best');

        $todayBest = ExerciseWeight::where('user_id', $user->id)
            ->whereDate('created_at', now()->toDateString())
            ->selectRaw('MAX(weight * (1 + reps / 30.0)) as best')
            ->value('best');

        // No weight logged today → nothing to compare
        if ($todayBest === null) {
            return 0;
        }

        // Historical record exists and today didn't beat it → no PR
        if ($historicalBest !== null && (float) $todayBest <= (float) $historicalBest) {
            return 0;
        }

        $alreadyGranted = PointTransaction::where('user_id', $user->id)
            ->where('type', 'earn')
            ->where('category', 'pr')
            ->whereDate('created_at', now()->toDateString())
            ->exists();

        if ($alreadyGranted) {
            return 0;
        }

        $bonus = (int) config('workout.pr_bonus', 5);
        $this->earnPoints($user, $bonus, 'Bônus de novo recorde pessoal', 'pr', $referenceId);

        return $bonus;
    }

    // recalcula do zero quando o saldo puder estar dessincronizado
    public function recalculateBalance(User $user): int
    {
        $earned = PointTransaction::where('user_id', $user->id)
            ->where('type', 'earn')
            ->sum('points');

        $spent = PointTransaction::where('user_id', $user->id)
            ->where('type', 'spend')
            ->sum('points');

        $balance = (int) ($earned - $spent);

        $user->update(['points_balance' => $balance]);

        return $balance;
    }
}
