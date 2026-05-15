<?php

namespace Database\Seeders;

use App\Models\CustomWorkout;
use App\Models\Exercise;
use App\Models\User;
use Illuminate\Database\Seeder;

class WorkoutTemplateSeeder extends Seeder
{
    public function run(): void
    {
        // Garantir que os exercícios usados existam (idempotente)
        $exercises = $this->ensureExercises();

        // Criar templates para o gym_admin de cada academia
        $admins = User::whereIn('role', ['gym_admin', 'super_admin'])
            ->whereNotNull('gym_id')
            ->get()
            ->unique('gym_id'); // um admin por academia

        if ($admins->isEmpty()) {
            $this->command->warn('WorkoutTemplateSeeder: nenhum gym_admin encontrado — pulando.');
            return;
        }

        $templates = [
            [
                'name'        => 'Treino A – Peito e Tríceps',
                'description' => 'Foco em peitoral maior e tríceps. Ideal para dias de empurrar.',
                'level'       => 'intermediate',
                'duration'    => 60,
                'exercises'   => [
                    ['name' => 'Supino Reto',          'sets' => 4, 'reps' => 10, 'rest' => 90],
                    ['name' => 'Supino Inclinado',     'sets' => 3, 'reps' => 12, 'rest' => 75],
                    ['name' => 'Tríceps Corda',        'sets' => 3, 'reps' => 15, 'rest' => 60],
                    ['name' => 'Tríceps Testa',        'sets' => 3, 'reps' => 12, 'rest' => 60],
                    ['name' => 'Crossover',            'sets' => 3, 'reps' => 15, 'rest' => 60],
                ],
            ],
            [
                'name'        => 'Treino B – Costas e Bíceps',
                'description' => 'Foco em latíssimo do dorso e bíceps. Dias de puxar.',
                'level'       => 'intermediate',
                'duration'    => 60,
                'exercises'   => [
                    ['name' => 'Puxada na Frente',     'sets' => 4, 'reps' => 10, 'rest' => 90],
                    ['name' => 'Remada Curvada',       'sets' => 4, 'reps' => 10, 'rest' => 90],
                    ['name' => 'Rosca Direta',         'sets' => 3, 'reps' => 12, 'rest' => 60],
                    ['name' => 'Rosca Martelo',        'sets' => 3, 'reps' => 12, 'rest' => 60],
                    ['name' => 'Remada Unilateral',    'sets' => 3, 'reps' => 12, 'rest' => 60],
                ],
            ],
            [
                'name'        => 'Treino C – Pernas Completo',
                'description' => 'Trabalha quadríceps, posterior e glúteos com volume moderado.',
                'level'       => 'intermediate',
                'duration'    => 70,
                'exercises'   => [
                    ['name' => 'Agachamento Livre',    'sets' => 4, 'reps' => 8,  'rest' => 120],
                    ['name' => 'Leg Press',            'sets' => 4, 'reps' => 12, 'rest' => 90],
                    ['name' => 'Cadeira Extensora',    'sets' => 3, 'reps' => 15, 'rest' => 60],
                    ['name' => 'Mesa Flexora',         'sets' => 3, 'reps' => 12, 'rest' => 60],
                    ['name' => 'Panturrilha no Leg',   'sets' => 4, 'reps' => 20, 'rest' => 45],
                ],
            ],
            [
                'name'        => 'Treino D – Ombros e Core',
                'description' => 'Deltoides e estabilizadores do core para postura e força funcional.',
                'level'       => 'beginner',
                'duration'    => 50,
                'exercises'   => [
                    ['name' => 'Desenvolvimento Halteres', 'sets' => 4, 'reps' => 10, 'rest' => 75],
                    ['name' => 'Elevação Lateral',         'sets' => 4, 'reps' => 15, 'rest' => 60],
                    ['name' => 'Elevação Frontal',         'sets' => 3, 'reps' => 12, 'rest' => 60],
                    ['name' => 'Abdominal',                'sets' => 4, 'reps' => 20, 'rest' => 45],
                    ['name' => 'Prancha',                  'sets' => 3, 'reps' => 45, 'rest' => 45],
                ],
            ],
            [
                'name'        => 'Treino Full Body – Iniciante',
                'description' => 'Treino completo para iniciantes. Trabalha todos os grupos musculares em 3x por semana.',
                'level'       => 'beginner',
                'duration'    => 45,
                'exercises'   => [
                    ['name' => 'Agachamento Livre',    'sets' => 3, 'reps' => 12, 'rest' => 90],
                    ['name' => 'Supino Reto',          'sets' => 3, 'reps' => 12, 'rest' => 90],
                    ['name' => 'Puxada na Frente',     'sets' => 3, 'reps' => 12, 'rest' => 90],
                    ['name' => 'Elevação Lateral',     'sets' => 3, 'reps' => 15, 'rest' => 60],
                    ['name' => 'Abdominal',            'sets' => 3, 'reps' => 20, 'rest' => 45],
                ],
            ],
            [
                'name'        => 'Cardio e Condicionamento',
                'description' => 'Sessão de condicionamento aeróbico e resistência muscular. Ótimo para dias de recuperação ativa.',
                'level'       => 'beginner',
                'duration'    => 40,
                'exercises'   => [
                    ['name' => 'Agachamento Livre',    'sets' => 4, 'reps' => 20, 'rest' => 45],
                    ['name' => 'Abdominal',            'sets' => 4, 'reps' => 25, 'rest' => 30],
                    ['name' => 'Prancha',              'sets' => 3, 'reps' => 60, 'rest' => 45],
                    ['name' => 'Leg Press',            'sets' => 3, 'reps' => 20, 'rest' => 45],
                    ['name' => 'Rosca Direta',         'sets' => 3, 'reps' => 20, 'rest' => 30],
                ],
            ],
        ];

        foreach ($admins as $admin) {
            foreach ($templates as $tpl) {
                $existing = CustomWorkout::where('name', $tpl['name'])
                    ->where('user_id', $admin->id)
                    ->where('is_template', true)
                    ->exists();

                if ($existing) {
                    continue;
                }

                $workout = CustomWorkout::create([
                    'user_id'      => $admin->id,
                    'name'         => $tpl['name'],
                    'description'  => $tpl['description'],
                    'level'        => $tpl['level'],
                    'duration'     => $tpl['duration'],
                    'is_generated' => false,
                    'is_template'  => true,
                ]);

                foreach ($tpl['exercises'] as $ex) {
                    $exercise = $exercises[$ex['name']] ?? null;
                    if (! $exercise) {
                        continue;
                    }
                    $workout->exercises()->attach($exercise->id, [
                        'sets' => $ex['sets'],
                        'reps' => $ex['reps'],
                        'rest' => $ex['rest'],
                    ]);
                }
            }
        }
    }

    private function ensureExercises(): array
    {
        $definitions = [
            ['name' => 'Supino Reto',              'muscle_group' => 'Peito'],
            ['name' => 'Supino Inclinado',         'muscle_group' => 'Peito'],
            ['name' => 'Crossover',                'muscle_group' => 'Peito'],
            ['name' => 'Tríceps Corda',            'muscle_group' => 'Tríceps'],
            ['name' => 'Tríceps Testa',            'muscle_group' => 'Tríceps'],
            ['name' => 'Puxada na Frente',         'muscle_group' => 'Costas'],
            ['name' => 'Remada Curvada',           'muscle_group' => 'Costas'],
            ['name' => 'Remada Unilateral',        'muscle_group' => 'Costas'],
            ['name' => 'Rosca Direta',             'muscle_group' => 'Bíceps'],
            ['name' => 'Rosca Martelo',            'muscle_group' => 'Bíceps'],
            ['name' => 'Agachamento Livre',        'muscle_group' => 'Pernas'],
            ['name' => 'Leg Press',                'muscle_group' => 'Pernas'],
            ['name' => 'Cadeira Extensora',        'muscle_group' => 'Pernas'],
            ['name' => 'Mesa Flexora',             'muscle_group' => 'Pernas'],
            ['name' => 'Panturrilha no Leg',       'muscle_group' => 'Pernas'],
            ['name' => 'Desenvolvimento Halteres', 'muscle_group' => 'Ombros'],
            ['name' => 'Elevação Lateral',         'muscle_group' => 'Ombros'],
            ['name' => 'Elevação Frontal',         'muscle_group' => 'Ombros'],
            ['name' => 'Abdominal',                'muscle_group' => 'Abdômen'],
            ['name' => 'Prancha',                  'muscle_group' => 'Abdômen'],
        ];

        $map = [];
        foreach ($definitions as $def) {
            $exercise = Exercise::firstOrCreate(
                ['name' => $def['name']],
                ['muscle_group' => $def['muscle_group']]
            );
            $map[$def['name']] = $exercise;
        }

        return $map;
    }
}
