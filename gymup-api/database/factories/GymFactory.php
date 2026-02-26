<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class GymFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => $this->faker->company,
            'email' => $this->faker->safeEmail,
            'phone' => $this->faker->phoneNumber,
            'address' => $this->faker->address,
            'active' => true,
        ];
    }
}