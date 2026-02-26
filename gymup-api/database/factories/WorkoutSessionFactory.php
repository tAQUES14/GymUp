<?php

namespace Database\Factories;

use App\Models\Gym;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\WorkoutSession>
 */
class WorkoutSessionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id'           => User::factory(),
            'gym_id'            => Gym::factory(),
            'started_at'        => Carbon::now(),
            'finished_at'       => null,
            'progress'          => 0,
            'points_granted'    => false,
            'points_granted_at' => null,
        ];
    }

    /** Session that has already been finished. */
    public function finished(): static
    {
        return $this->state(fn (array $attributes) => [
            'finished_at' => Carbon::now()->addMinutes(15),
        ]);
    }

    /** Session where points were already granted (e.g. for testing duplicate prevention). */
    public function withPointsGranted(): static
    {
        return $this->state(fn (array $attributes) => [
            'points_granted'    => true,
            'points_granted_at' => Carbon::now(),
        ]);
    }
}
