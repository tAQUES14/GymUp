<?php

namespace Database\Seeders;

use App\Models\Exercise;
use App\Models\Gym;
use App\Models\WorkoutExercise;
use App\Models\WorkoutPlan;
use App\Models\WorkoutPlanDay;
use Illuminate\Database\Seeder;

class WorkoutPlanSeeder extends Seeder
{
    public function run(): void
    {
        // ── 1. Seed additional exercises ──────────────────────────────────────

        $extraExercises = [
            // Peito
            ['name' => 'Supino Inclinado com Halteres', 'muscle_group' => 'Peito',    'default_rest' => 90],
            ['name' => 'Crucifixo com Halteres',        'muscle_group' => 'Peito',    'default_rest' => 60],
            ['name' => 'Flexão de Braços',               'muscle_group' => 'Peito',    'default_rest' => 60],
            ['name' => 'Crossover no Cabo',              'muscle_group' => 'Peito',    'default_rest' => 60],
            ['name' => 'Supino Declinado',               'muscle_group' => 'Peito',    'default_rest' => 90],

            // Costas
            ['name' => 'Remada Curvada com Barra',       'muscle_group' => 'Costas',   'default_rest' => 90],
            ['name' => 'Remada com Halteres',            'muscle_group' => 'Costas',   'default_rest' => 60],
            ['name' => 'Barra Fixa',                     'muscle_group' => 'Costas',   'default_rest' => 90],
            ['name' => 'Remada Sentada no Cabo',         'muscle_group' => 'Costas',   'default_rest' => 60],
            ['name' => 'Remada Unilateral',              'muscle_group' => 'Costas',   'default_rest' => 60],

            // Ombros
            ['name' => 'Desenvolvimento com Halteres',   'muscle_group' => 'Ombros',   'default_rest' => 90],
            ['name' => 'Elevação Frontal',               'muscle_group' => 'Ombros',   'default_rest' => 60],
            ['name' => 'Press Militar com Barra',        'muscle_group' => 'Ombros',   'default_rest' => 90],
            ['name' => 'Encolhimento',                   'muscle_group' => 'Ombros',   'default_rest' => 60],

            // Bíceps
            ['name' => 'Rosca Alternada com Halteres',   'muscle_group' => 'Bíceps',   'default_rest' => 60],
            ['name' => 'Rosca Martelo',                  'muscle_group' => 'Bíceps',   'default_rest' => 60],
            ['name' => 'Rosca Concentrada',              'muscle_group' => 'Bíceps',   'default_rest' => 60],
            ['name' => 'Rosca Scott',                    'muscle_group' => 'Bíceps',   'default_rest' => 60],

            // Tríceps
            ['name' => 'Tríceps Francês com Barra',      'muscle_group' => 'Tríceps',  'default_rest' => 60],
            ['name' => 'Extensão de Tríceps com Haltere','muscle_group' => 'Tríceps',  'default_rest' => 60],
            ['name' => 'Fundos (Dips)',                  'muscle_group' => 'Tríceps',  'default_rest' => 90],
            ['name' => 'Tríceps Coice',                  'muscle_group' => 'Tríceps',  'default_rest' => 60],
            ['name' => 'Skull Crusher',                  'muscle_group' => 'Tríceps',  'default_rest' => 60],

            // Pernas
            ['name' => 'Stiff com Barra',                'muscle_group' => 'Pernas',   'default_rest' => 90],
            ['name' => 'Avanço com Halteres',            'muscle_group' => 'Pernas',   'default_rest' => 60],
            ['name' => 'Panturrilha em Pé',              'muscle_group' => 'Pernas',   'default_rest' => 45],
            ['name' => 'Agachamento Búlgaro',            'muscle_group' => 'Pernas',   'default_rest' => 90],
            ['name' => 'Cadeira Extensora',              'muscle_group' => 'Pernas',   'default_rest' => 60],
            ['name' => 'Mesa Flexora',                   'muscle_group' => 'Pernas',   'default_rest' => 60],

            // Core/Abdômen
            ['name' => 'Prancha',                        'muscle_group' => 'Abdômen',  'default_rest' => 45],
            ['name' => 'Abdominal Bicicleta',            'muscle_group' => 'Abdômen',  'default_rest' => 45],
            ['name' => 'Elevação de Pernas',             'muscle_group' => 'Abdômen',  'default_rest' => 45],
            ['name' => 'Russian Twist',                  'muscle_group' => 'Abdômen',  'default_rest' => 45],
            ['name' => 'Abdominal Oblíquo',              'muscle_group' => 'Abdômen',  'default_rest' => 45],
        ];

        $cardioExercises = [
            ['name' => 'Esteira',              'muscle_group' => 'Cardio', 'default_rest' => 0],
            ['name' => 'Bike Ergométrica',     'muscle_group' => 'Cardio', 'default_rest' => 0],
            ['name' => 'Elíptico',             'muscle_group' => 'Cardio', 'default_rest' => 0],
            ['name' => 'Corda',                'muscle_group' => 'Cardio', 'default_rest' => 30],
            ['name' => 'Remo Ergométrico',     'muscle_group' => 'Cardio', 'default_rest' => 0],
            ['name' => 'Escada Rolante',       'muscle_group' => 'Cardio', 'default_rest' => 0],
            ['name' => 'Caminhada Inclinada',  'muscle_group' => 'Cardio', 'default_rest' => 0],
            ['name' => 'Corrida Leve',         'muscle_group' => 'Cardio', 'default_rest' => 0],
        ];

        foreach ($extraExercises as $ex) {
            Exercise::firstOrCreate(
                ['name' => $ex['name']],
                [
                    'type'         => 'strength',
                    'muscle_group' => $ex['muscle_group'],
                    'default_rest' => $ex['default_rest'],
                    'image_url'    => null,
                ]
            );
        }

        foreach ($cardioExercises as $ex) {
            Exercise::firstOrCreate(
                ['name' => $ex['name']],
                [
                    'type'         => 'cardio',
                    'muscle_group' => $ex['muscle_group'],
                    'default_rest' => $ex['default_rest'],
                    'image_url'    => null,
                ]
            );
        }

        // ── 2. Helper to resolve exercise id by name ──────────────────────────

        $gym = Gym::first();

        if (!$gym) {
            $this->command->warn('No gym found — skipping WorkoutPlanSeeder plan creation.');
            return;
        }

        $ex = fn (string $name): int => Exercise::where('name', $name)->firstOrFail()->id;

        // ── 3. Create 4 workout plans ─────────────────────────────────────────

        $this->createPlan($gym->id, 'Iniciante 3x', 'Plano para iniciantes com 3 treinos por semana de corpo inteiro.', [
            [
                'name'     => 'Full Body A',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Agachamento Livre'),              'sets' => 3, 'reps' => '12', 'rest_seconds' => 90],
                    ['id' => $ex('Supino Reto'),                    'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Puxada na Frente'),               'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Elevação Lateral'),               'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Rosca Direta'),                   'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Tríceps Corda'),                  'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Abdominal'),                      'sets' => 3, 'reps' => '20', 'rest_seconds' => 45],
                ],
            ],
            ['name' => 'Descanso', 'rest_day' => true, 'exercises' => []],
            [
                'name'     => 'Full Body B',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Leg Press'),                      'sets' => 4, 'reps' => '12', 'rest_seconds' => 90],
                    ['id' => $ex('Supino Inclinado com Halteres'),  'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Remada com Halteres'),            'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Desenvolvimento com Halteres'),   'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Rosca Alternada com Halteres'),   'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Extensão de Tríceps com Haltere'),'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Prancha'),                        'sets' => 3, 'reps' => '30s','rest_seconds' => 45],
                ],
            ],
            ['name' => 'Descanso', 'rest_day' => true, 'exercises' => []],
            [
                'name'     => 'Full Body C',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Avanço com Halteres'),            'sets' => 3, 'reps' => '10', 'rest_seconds' => 60],
                    ['id' => $ex('Supino Declinado'),               'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Remada Curvada com Barra'),       'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Press Militar com Barra'),        'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Rosca Martelo'),                  'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Fundos (Dips)'),                  'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Elevação de Pernas'),             'sets' => 3, 'reps' => '15', 'rest_seconds' => 45],
                ],
            ],
            ['name' => 'Descanso', 'rest_day' => true, 'exercises' => []],
        ]);

        $this->createPlan($gym->id, 'Full Body 4x', 'Treino de corpo inteiro com 4 sessões por semana.', [
            [
                'name'     => 'Full Body A',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Agachamento Livre'),              'sets' => 4, 'reps' => '8',  'rest_seconds' => 120],
                    ['id' => $ex('Supino Reto'),                    'sets' => 4, 'reps' => '8',  'rest_seconds' => 120],
                    ['id' => $ex('Remada Curvada com Barra'),       'sets' => 4, 'reps' => '8',  'rest_seconds' => 90],
                    ['id' => $ex('Press Militar com Barra'),        'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Rosca Direta'),                   'sets' => 3, 'reps' => '10', 'rest_seconds' => 60],
                    ['id' => $ex('Tríceps Corda'),                  'sets' => 3, 'reps' => '10', 'rest_seconds' => 60],
                    ['id' => $ex('Abdominal'),                      'sets' => 3, 'reps' => '20', 'rest_seconds' => 45],
                    ['id' => $ex('Elevação de Pernas'),             'sets' => 3, 'reps' => '15', 'rest_seconds' => 45],
                ],
            ],
            ['name' => 'Descanso', 'rest_day' => true, 'exercises' => []],
            [
                'name'     => 'Full Body B',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Leg Press'),                      'sets' => 4, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Supino Inclinado com Halteres'),  'sets' => 4, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Puxada na Frente'),               'sets' => 4, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Desenvolvimento com Halteres'),   'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Rosca Alternada com Halteres'),   'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Extensão de Tríceps com Haltere'),'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Prancha'),                        'sets' => 3, 'reps' => '30s','rest_seconds' => 45],
                    ['id' => $ex('Russian Twist'),                  'sets' => 3, 'reps' => '20', 'rest_seconds' => 45],
                ],
            ],
            ['name' => 'Descanso', 'rest_day' => true, 'exercises' => []],
        ]);

        $this->createPlan($gym->id, 'Upper/Lower', 'Divisão de treino superior e inferior, 4 dias por semana.', [
            [
                'name'     => 'Upper A',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Supino Reto'),              'sets' => 4, 'reps' => '8',  'rest_seconds' => 120],
                    ['id' => $ex('Remada Curvada com Barra'), 'sets' => 4, 'reps' => '8',  'rest_seconds' => 90],
                    ['id' => $ex('Press Militar com Barra'),  'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Puxada na Frente'),         'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Rosca Direta'),             'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Skull Crusher'),            'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                ],
            ],
            [
                'name'     => 'Lower A',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Agachamento Livre'),   'sets' => 4, 'reps' => '8',  'rest_seconds' => 120],
                    ['id' => $ex('Leg Press'),           'sets' => 3, 'reps' => '12', 'rest_seconds' => 90],
                    ['id' => $ex('Stiff com Barra'),     'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Cadeira Extensora'),   'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Mesa Flexora'),        'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Panturrilha em Pé'),   'sets' => 4, 'reps' => '15', 'rest_seconds' => 45],
                ],
            ],
            ['name' => 'Descanso', 'rest_day' => true, 'exercises' => []],
            [
                'name'     => 'Upper B',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Supino Inclinado com Halteres'), 'sets' => 4, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Remada com Halteres'),           'sets' => 4, 'reps' => '10', 'rest_seconds' => 60],
                    ['id' => $ex('Elevação Lateral'),              'sets' => 3, 'reps' => '15', 'rest_seconds' => 60],
                    ['id' => $ex('Barra Fixa'),                    'sets' => 3, 'reps' => '8',  'rest_seconds' => 90],
                    ['id' => $ex('Rosca Martelo'),                 'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Fundos (Dips)'),                 'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                ],
            ],
            [
                'name'     => 'Lower B',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Agachamento Búlgaro'), 'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Leg Press'),           'sets' => 4, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Avanço com Halteres'), 'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Mesa Flexora'),        'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Panturrilha em Pé'),   'sets' => 4, 'reps' => '20', 'rest_seconds' => 45],
                    ['id' => $ex('Prancha'),             'sets' => 3, 'reps' => '45s','rest_seconds' => 45],
                ],
            ],
            ['name' => 'Descanso', 'rest_day' => true, 'exercises' => []],
        ]);

        $this->createPlan($gym->id, 'Push Pull Legs', 'Divisão PPL clássica: empurrar, puxar e pernas.', [
            [
                'name'     => 'Push',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Supino Reto'),                   'sets' => 4, 'reps' => '8',  'rest_seconds' => 120],
                    ['id' => $ex('Supino Inclinado com Halteres'), 'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Crucifixo com Halteres'),        'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Press Militar com Barra'),       'sets' => 4, 'reps' => '8',  'rest_seconds' => 90],
                    ['id' => $ex('Elevação Lateral'),              'sets' => 3, 'reps' => '15', 'rest_seconds' => 60],
                    ['id' => $ex('Elevação Frontal'),              'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Tríceps Corda'),                 'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Skull Crusher'),                 'sets' => 3, 'reps' => '10', 'rest_seconds' => 60],
                ],
            ],
            [
                'name'     => 'Pull',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Barra Fixa'),                   'sets' => 4, 'reps' => '8',  'rest_seconds' => 120],
                    ['id' => $ex('Remada Curvada com Barra'),     'sets' => 4, 'reps' => '8',  'rest_seconds' => 90],
                    ['id' => $ex('Puxada na Frente'),             'sets' => 3, 'reps' => '12', 'rest_seconds' => 90],
                    ['id' => $ex('Remada Sentada no Cabo'),       'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Remada Unilateral'),            'sets' => 3, 'reps' => '10', 'rest_seconds' => 60],
                    ['id' => $ex('Rosca Direta'),                 'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                    ['id' => $ex('Rosca Alternada com Halteres'), 'sets' => 3, 'reps' => '12', 'rest_seconds' => 60],
                ],
            ],
            [
                'name'     => 'Legs',
                'rest_day' => false,
                'exercises' => [
                    ['id' => $ex('Agachamento Livre'),   'sets' => 4, 'reps' => '8',  'rest_seconds' => 120],
                    ['id' => $ex('Leg Press'),           'sets' => 4, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Stiff com Barra'),     'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Agachamento Búlgaro'), 'sets' => 3, 'reps' => '10', 'rest_seconds' => 90],
                    ['id' => $ex('Cadeira Extensora'),   'sets' => 3, 'reps' => '15', 'rest_seconds' => 60],
                    ['id' => $ex('Mesa Flexora'),        'sets' => 3, 'reps' => '15', 'rest_seconds' => 60],
                    ['id' => $ex('Panturrilha em Pé'),   'sets' => 5, 'reps' => '20', 'rest_seconds' => 45],
                    ['id' => $ex('Prancha'),             'sets' => 3, 'reps' => '60s','rest_seconds' => 45],
                ],
            ],
            ['name' => 'Descanso', 'rest_day' => true, 'exercises' => []],
        ]);
    }

    private function createPlan(int $gymId, string $name, string $description, array $days): void
    {
        // Skip if plan already exists
        if (WorkoutPlan::where('gym_id', $gymId)->where('name', $name)->exists()) {
            return;
        }

        $plan = WorkoutPlan::create([
            'gym_id'      => $gymId,
            'name'        => $name,
            'description' => $description,
        ]);

        foreach ($days as $dayOrder => $dayData) {
            // Mapeia índice 0-based para dia da semana começando na segunda:
            // 0→1(Seg), 1→2(Ter), 2→3(Qua), 3→4(Qui), 4→5(Sex), 5→6(Sáb), 6→0(Dom)
            $dow = ($dayOrder + 1) % 7;

            $day = WorkoutPlanDay::create([
                'plan_id'     => $plan->id,
                'day_of_week' => $dow,
                'name'        => $dayData['name'],
                'rest_day'    => $dayData['rest_day'],
            ]);

            foreach ($dayData['exercises'] as $exOrder => $exData) {
                WorkoutExercise::create([
                    'plan_day_id'      => $day->id,
                    'exercise_id'      => $exData['id'],
                    'sets'             => $exData['sets'] ?? null,
                    'reps'             => isset($exData['reps']) ? (string) $exData['reps'] : null,
                    'rest_seconds'     => $exData['rest_seconds'] ?? 60,
                    'exercise_order'   => $exOrder + 1,
                    'duration_minutes' => $exData['duration_minutes'] ?? null,
                    'distance_km'      => $exData['distance_km'] ?? null,
                ]);
            }
        }
    }
}
