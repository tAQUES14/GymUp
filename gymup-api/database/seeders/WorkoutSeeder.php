<?php

namespace Database\Seeders;

use App\Models\CustomWorkout;
use App\Models\Exercise;
use App\Models\User;
use Illuminate\Database\Seeder;

class WorkoutSeeder extends Seeder
{
    public function run(): void
    {
        // ── 1. Usuário de teste ────────────────────────────────────────────────
        // O WorkoutSeeder deve rodar após a criação do usuário no DatabaseSeeder.
        $user = User::where('email', 'test@example.com')->firstOrFail();

        // ── 2. Exercícios ─────────────────────────────────────────────────────
        // ExerciseSeeder já criou: Supino Reto, Agachamento Livre, Rosca Direta.
        // firstOrCreate garante idempotência mesmo fora de migrate:fresh.
        $supinoReto = Exercise::firstOrCreate(
            ['name' => 'Supino Reto'],
            ['muscle_group' => 'Peito', 'default_rest' => 60]
        );

        $agachamento = Exercise::firstOrCreate(
            ['name' => 'Agachamento Livre'],
            ['muscle_group' => 'Pernas', 'default_rest' => 60]
        );

        $remadaCurvada = Exercise::firstOrCreate(
            ['name' => 'Remada Curvada'],
            ['muscle_group' => 'Costas', 'default_rest' => 45]
        );

        $roscaDireta = Exercise::firstOrCreate(
            ['name' => 'Rosca Direta'],
            ['muscle_group' => 'Bíceps', 'default_rest' => 45]
        );

        // ── 3. Treino ─────────────────────────────────────────────────────────
        $workout = CustomWorkout::firstOrCreate(
            [
                'user_id' => $user->id,
                'name'    => 'Treino A – Força e Hipertrofia',
            ],
            [
                'description'  => 'Treino completo com foco em empurrar, puxar e membros inferiores.',
                'level'        => 'Intermediário',
                'duration'     => 60,
                'is_generated' => false,
            ]
        );

        // ── 4. Pivot: exercícios → treino ─────────────────────────────────────
        // sync() é idempotente: recria os pivots a cada seed sem duplicar.
        // Colunas do pivot: sets, reps, rest (definidas na migration).
        $workout->exercises()->sync([
            $supinoReto->id => [
                'sets' => 4,
                'reps' => 10,
                'rest' => 60,
            ],
            $agachamento->id => [
                'sets' => 4,
                'reps' => 10,
                'rest' => 60,
            ],
            $remadaCurvada->id => [
                'sets' => 3,
                'reps' => 12,
                'rest' => 45,
            ],
            $roscaDireta->id => [
                'sets' => 3,
                'reps' => 12,
                'rest' => 45,
            ],
        ]);

        $this->command->info("Treino '{$workout->name}' criado com {$workout->exercises()->count()} exercícios para o usuário {$user->email}.");
    }
}
