<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use App\Models\User;
use App\Models\Reward;
use App\Models\Gym;

class RedemptionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'reward_id' => Reward::factory(),
            'gym_id' => Gym::factory(),
            'points_spent' => 20,
            'status' => 'pending',
        ];
    }
}