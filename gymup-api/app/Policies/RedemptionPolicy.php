<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Redemption;

class RedemptionPolicy
{
    public function approve(User $user, Redemption $redemption): bool
    {
        return $user->role === 'admin'
            && $user->gym_id === $redemption->gym_id
            && $redemption->status === 'pending';
    }

    public function viewAny(User $user): bool
    {
        return $user->role === 'admin';
    }
}