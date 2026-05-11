<?php

namespace Database\Factories;

use App\Models\Gym;
use App\Models\User;
use App\Models\WorkoutSession;
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
        return $this->state(function (array $attributes) {
            $startedAt = $attributes['started_at'] ?? now()->subMinutes(45);
            return [
                'finished_at' => Carbon::parse($startedAt)->addMinutes(30),
                'progress'    => 100,
            ];
        });
    }

    /** Session where points were already granted (e.g. for testing duplicate prevention). */
    public function withPointsGranted(): static
    {
        return $this->afterCreating(function (WorkoutSession $session) {
            // Refresh to pick up finished_at if set by the finished() afterCreating above.
            $session->refresh();
            $session->update([
                'points_granted'    => true,
                'points_granted_at' => ($session->finished_at ?? $session->started_at->copy()->addMinutes(30)),
            ]);
        });
    }
}
