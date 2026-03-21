<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AchievementSeeder extends Seeder
{
    public function run(): void
    {
        $achievements = [
            [
                'code'          => 'first_workout',
                'title'         => 'Primeiro treino',
                'description'   => 'Complete seu primeiro treino',
                'metric'        => 'workouts_total',
                'target_value'  => 1,
                'points_reward' => 10,
                'icon'          => 'fitness',
            ],
            [
                'code'          => 'five_workouts',
                'title'         => '5 treinos concluídos',
                'description'   => 'Complete 5 treinos',
                'metric'        => 'workouts_total',
                'target_value'  => 5,
                'points_reward' => 20,
                'icon'          => 'fitness',
            ],
            [
                'code'          => 'ten_workouts',
                'title'         => '10 treinos concluídos',
                'description'   => 'Complete 10 treinos',
                'metric'        => 'workouts_total',
                'target_value'  => 10,
                'points_reward' => 40,
                'icon'          => 'fitness',
            ],
            [
                'code'          => 'twenty_workouts',
                'title'         => '20 treinos concluídos',
                'description'   => 'Complete 20 treinos',
                'metric'        => 'workouts_total',
                'target_value'  => 20,
                'points_reward' => 80,
                'icon'          => 'fitness',
            ],
            [
                'code'          => 'streak_3',
                'title'         => 'Streak de 3 dias',
                'description'   => 'Treine por 3 dias seguidos',
                'metric'        => 'streak_days',
                'target_value'  => 3,
                'points_reward' => 30,
                'icon'          => 'streak',
            ],
            [
                'code'          => 'streak_7',
                'title'         => 'Streak de 7 dias',
                'description'   => 'Treine por 7 dias seguidos',
                'metric'        => 'streak_days',
                'target_value'  => 7,
                'points_reward' => 70,
                'icon'          => 'streak',
            ],
        ];

        foreach ($achievements as $achievement) {
            DB::table('achievements')->updateOrInsert(
                ['code' => $achievement['code']],
                array_merge($achievement, [
                    'created_at' => now(),
                    'updated_at' => now(),
                ]),
            );
        }
    }
}
