<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class GymChainFactory extends Factory
{
    public function definition(): array
    {
        $name = $this->faker->unique()->company;

        return [
            'name'     => $name,
            'slug'     => Str::slug($name) . '-' . $this->faker->unique()->randomNumber(4),
            'logo_url' => null,
        ];
    }
}
