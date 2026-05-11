<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Redemption;

class RedemptionPolicy
{
    public function approve(User $user, Redemption $redemption): bool
    {
        return $user->hasPermission('manage_redemptions')
            && $redemption->status === 'pending';
    }

    public function viewAny(User $user): bool
    {
        return $user->hasPermission('manage_redemptions');
    }
}