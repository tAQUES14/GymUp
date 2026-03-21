<?php

namespace Database\Seeders;

use App\Models\Gym;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // ── 1. Academia ────────────────────────────────────────────────────────
        $this->call(GymSeeder::class);

        // ── 2. Catálogo de exercícios ──────────────────────────────────────────
        $this->call(ExerciseSeeder::class);

        // ── 3. Usuário de teste (aluno) ────────────────────────────────────────
        User::firstOrCreate(
            ['email' => 'test@example.com'],
            [
                'name'   => 'Test User',
                'gym_id' => Gym::first()->id,
                'role'   => 'user',
            ]
        );

        // ── 3b. Super admin de teste ───────────────────────────────────────────
        User::firstOrCreate(
            ['email' => 'admin@gymup.app'],
            [
                'name'     => 'Admin GymUp',
                'gym_id'   => Gym::first()->id,
                'role'     => 'super_admin',
                'password' => bcrypt('admin123'),
            ]
        );

        // ── 4. Treino padrão vinculado ao usuário de teste ─────────────────────
        // Deve rodar APÓS a criação do usuário — WorkoutSeeder busca por e-mail.
        $this->call(WorkoutSeeder::class);

        // ── 5. Recompensas de exemplo ────────────────────────────────────────
        $this->call(RewardSeeder::class);

        // ── 6. Conquistas padrão ──────────────────────────────────────────────
        $this->call(AchievementSeeder::class);

        // ── 7. Planos de treino sequenciais ───────────────────────────────────
        $this->call(WorkoutPlanSeeder::class);
    }
}
