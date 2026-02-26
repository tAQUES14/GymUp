<?php

namespace App\Services;

use App\Models\PointTransaction;
use App\Models\User;

class PointService
{
    public function earnPoints(User $user, int $points, string $description)
    {
        PointTransaction::create([
            'user_id' => $user->id,
            'gym_id' => $user->gym_id,
            'type' => 'earn',
            'points' => $points,
            'description' => $description
        ]);

        $user->increment('points_balance', $points);
    }

    public function spendPoints(User $user, int $points, string $description)
    {
        if ($user->points_balance < $points) {
            throw new \Exception('Saldo insuficiente.');
        }

        PointTransaction::create([
            'user_id' => $user->id,
            'gym_id' => $user->gym_id,
            'type' => 'spend',
            'points' => $points,
            'description' => $description
        ]);

        $user->decrement('points_balance', $points);
    }
}