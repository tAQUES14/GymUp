<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use App\Models\Gym;

class RewardFactory extends Factory
{
    public function definition(): array
    {
        return [
            'gym_id' => Gym::factory(),
            'name' => $this->faker->word,
            'description' => $this->faker->sentence,
            'points_cost' => 20,
            'stock' => 10,
            'active' => true,
        ];
    }
}