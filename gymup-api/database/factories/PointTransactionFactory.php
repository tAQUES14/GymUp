<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use App\Models\User;
use App\Models\Gym;

class PointTransactionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'gym_id' => Gym::factory(),
            'type' => 'earn',
            'points' => 10,
            'description' => $this->faker->sentence,
        ];
    }
}