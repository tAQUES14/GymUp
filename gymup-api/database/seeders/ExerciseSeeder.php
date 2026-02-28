<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Exercise;

class ExerciseSeeder extends Seeder
{
    public function run(): void
    {
        $exercises = [
            ['name' => 'Supino Reto', 'muscle_group' => 'Peito'],
            ['name' => 'Agachamento Livre', 'muscle_group' => 'Pernas'],
            ['name' => 'Puxada na Frente', 'muscle_group' => 'Costas'],
            ['name' => 'Rosca Direta', 'muscle_group' => 'Bíceps'],
            ['name' => 'Tríceps Corda', 'muscle_group' => 'Tríceps'],
            ['name' => 'Elevação Lateral', 'muscle_group' => 'Ombros'],
            ['name' => 'Leg Press', 'muscle_group' => 'Pernas'],
            ['name' => 'Abdominal', 'muscle_group' => 'Core'],
        ];

        foreach ($exercises as $exercise) {
            Exercise::create($exercise);
        }
    }
}