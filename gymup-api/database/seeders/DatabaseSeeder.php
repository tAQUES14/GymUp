<?php

namespace Database\Seeders;

use App\Models\Gym;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            GymSeeder::class,
            ExerciseSeeder::class,
        ]);

        User::factory()->create([
            'name'   => 'Test User',
            'email'  => 'test@example.com',
            'gym_id' => Gym::first()->id,
        ]);
    }
}
