<?php

namespace App\Services;

use App\Models\ExerciseWeight;
use App\Models\PointTransaction;
use App\Models\User;

class PointService
{
    /**
     * Earn points and log the transaction.
     *
     * @param  User    $user
     * @param  int     $points
     * @param  string  $description
     * @param  string  $category     workout|streak|pr
     * @param  int|null $referenceId  Optional FK to the source record (e.g. workout_session id)
     */
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

    /**
     * Spend points (e.g. for reward redemption).
     *
     * @param  User    $user
     * @param  int     $points
     * @param  string  $description
     * @param  string  $category     redemption
     * @param  int|null $referenceId
     */
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

    /**
     * Grant streak bonus when the user extends their streak to 2+ consecutive days.
     * Idempotent: no-op if bonus was already granted today.
     *
     * @return int  Points actually granted (0 if not applicable or already granted).
     */
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

    /**
     * Grant PR bonus when the user's best e1RM today beats their all-time best.
     * Idempotent: no-op if bonus was already granted today.
     *
     * @return int  Points actually granted (0 if no PR or already granted).
     */
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

    /**
     * Recalculate points_balance from the ledger (point_transactions).
     * Use when balance might be out of sync.
     */
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
