<?php

namespace Database\Seeders;

use App\Models\Checkin;
use App\Models\Gym;
use App\Models\GymChain;
use App\Models\PointTransaction;
use App\Models\User;
use App\Models\WorkoutSession;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class NetworkTestSeeder extends Seeder
{
    public function run(): void
    {
        // ── 1. Super admin ────────────────────────────────────────────────────

        $superAdmin = User::updateOrCreate(
            ['email' => 'super@gymup.test'],
            [
                'name'     => 'Super Admin GymUp',
                'gym_id'   => null,
                'role'     => 'super_admin',
                'password' => Hash::make('password'),
            ]
        );

        // ── 2. Rede ───────────────────────────────────────────────────────────

        $chain = GymChain::firstOrCreate(
            ['slug' => 'tnt-academias'],
            ['name' => 'TNT Academias', 'logo_url' => null]
        );

        // ── 3. Filiais da rede ────────────────────────────────────────────────

        $gymGuamiranga = $this->upsertGym('TNT Guamiranga', [
            'city'     => 'Guamiranga',
            'chain_id' => $chain->id,
            'active'   => true,
        ]);

        $gymPrudentopolis = $this->upsertGym('TNT Prudentópolis', [
            'city'     => 'Prudentópolis',
            'chain_id' => $chain->id,
            'active'   => true,
        ]);

        $gymMalharte = $this->upsertGym('TNT Malharte', [
            'city'     => 'Guarapuava',
            'chain_id' => $chain->id,
            'active'   => true,
        ]);

        // ── 4. Academia independente ──────────────────────────────────────────

        $gymIndep = $this->upsertGym('Academia Independente', [
            'city'     => 'Guarapuava',
            'chain_id' => null,
            'active'   => true,
        ]);

        // ── 5. Network admin ──────────────────────────────────────────────────

        $networkAdmin = User::updateOrCreate(
            ['email' => 'network@gymup.test'],
            [
                'name'     => 'Network Admin TNT',
                'gym_id'   => $gymGuamiranga->id,
                'role'     => 'network_admin',
                'password' => Hash::make('password'),
            ]
        );
        if ($networkAdmin->gym_id !== $gymGuamiranga->id) {
            $networkAdmin->update(['gym_id' => $gymGuamiranga->id]);
        }

        // ── 6. Gym admins (um por academia) ───────────────────────────────────

        $adminGuamiranga = User::updateOrCreate(
            ['email' => 'admin.guamiranga@gymup.test'],
            [
                'name'     => 'Admin TNT Guamiranga',
                'gym_id'   => $gymGuamiranga->id,
                'role'     => 'gym_admin',
                'password' => Hash::make('password'),
            ]
        );

        $adminPrude = User::updateOrCreate(
            ['email' => 'admin.prude@gymup.test'],
            [
                'name'     => 'Admin TNT Prudentópolis',
                'gym_id'   => $gymPrudentopolis->id,
                'role'     => 'gym_admin',
                'password' => Hash::make('password'),
            ]
        );

        $adminMalharte = User::updateOrCreate(
            ['email' => 'admin.malharte@gymup.test'],
            [
                'name'     => 'Admin TNT Malharte',
                'gym_id'   => $gymMalharte->id,
                'role'     => 'gym_admin',
                'password' => Hash::make('password'),
            ]
        );

        $adminIndep = User::updateOrCreate(
            ['email' => 'admin.independente@gymup.test'],
            [
                'name'     => 'Admin Academia Independente',
                'gym_id'   => $gymIndep->id,
                'role'     => 'gym_admin',
                'password' => Hash::make('password'),
            ]
        );

        // ── 7. Trainers ───────────────────────────────────────────────────────

        $trainerTriplo = User::updateOrCreate(
            ['email' => 'trainer.triplo@gymup.test'],
            [
                'name'     => 'Trainer Triplo TNT',
                'gym_id'   => $gymGuamiranga->id,
                'role'     => 'trainer',
                'password' => Hash::make('password'),
            ]
        );

        // Vincula às 3 filiais (Guamiranga é primary)
        $this->attachGym($trainerTriplo, $gymGuamiranga->id,     isPrimary: true);
        $this->attachGym($trainerTriplo, $gymPrudentopolis->id,  isPrimary: false);
        $this->attachGym($trainerTriplo, $gymMalharte->id,       isPrimary: false);

        $trainerSimples = User::updateOrCreate(
            ['email' => 'trainer.simples@gymup.test'],
            [
                'name'     => 'Trainer Simples TNT',
                'gym_id'   => $gymGuamiranga->id,
                'role'     => 'trainer',
                'password' => Hash::make('password'),
            ]
        );

        $this->attachGym($trainerSimples, $gymGuamiranga->id, isPrimary: true);

        // ── 8. Alunos ─────────────────────────────────────────────────────────

        $students = [
            ['email' => 'aluno.guamiranga1@gymup.test', 'name' => 'Aluno Guamiranga 1', 'gym' => $gymGuamiranga,     'pts' => 100],
            ['email' => 'aluno.guamiranga2@gymup.test', 'name' => 'Aluno Guamiranga 2', 'gym' => $gymGuamiranga,     'pts' => 50],
            ['email' => 'aluno.prude1@gymup.test',      'name' => 'Aluno Prude 1',      'gym' => $gymPrudentopolis,  'pts' => 80],
            ['email' => 'aluno.prude2@gymup.test',      'name' => 'Aluno Prude 2',      'gym' => $gymPrudentopolis,  'pts' => 30],
            ['email' => 'aluno.malharte1@gymup.test',   'name' => 'Aluno Malharte 1',   'gym' => $gymMalharte,       'pts' => 60],
            ['email' => 'aluno.independente@gymup.test','name' => 'Aluno Independente',  'gym' => $gymIndep,          'pts' => 40],
        ];

        $studentModels = [];
        foreach ($students as $s) {
            $student = User::updateOrCreate(
                ['email' => $s['email']],
                [
                    'name'           => $s['name'],
                    'gym_id'         => $s['gym']->id,
                    'role'           => 'user',
                    'password'       => Hash::make('password'),
                    'points_balance' => $s['pts'],
                ]
            );
            $studentModels[$s['email']] = $student;
        }

        // ── 9. Sessões de treino concluídas (alimentam o ranking) ─────────────

        $baseDate = Carbon::now()->subDays(3);

        foreach ($studentModels as $email => $student) {
            // Cria 2 sessões concluídas por aluno (se ainda não existirem)
            $existing = WorkoutSession::where('user_id', $student->id)
                ->where('points_granted', true)
                ->where('checkin_gym_id', null)
                ->count();

            if ($existing < 2) {
                for ($i = 0; $i < 2; $i++) {
                    WorkoutSession::create([
                        'user_id'        => $student->id,
                        'gym_id'         => $student->gym_id,
                        'started_at'     => $baseDate->copy()->subHours(2),
                        'finished_at'    => $baseDate->copy(),
                        'progress'       => 100,
                        'points_granted' => true,
                    ]);
                }

                // Transações de pontos correspondentes
                PointTransaction::create([
                    'user_id'     => $student->id,
                    'gym_id'      => $student->gym_id,
                    'type'        => 'earn',
                    'category'    => 'workout',
                    'points'      => $student->points_balance,
                    'description' => 'Pontos iniciais (seeder)',
                ]);
            }
        }

        // ── 10. Check-ins desta semana (alimentam dashboard da rede) ──────────

        $today     = Carbon::today()->toDateString();
        $yesterday = Carbon::yesterday()->toDateString();

        foreach ($studentModels as $student) {
            if ($student->gym_id === $gymIndep->id) continue; // pula academia independente

            if (! Checkin::where('user_id', $student->id)->where('checkin_date', $today)->exists()) {
                Checkin::create([
                    'user_id'      => $student->id,
                    'gym_id'       => $student->gym_id,
                    'checkin_date' => $today,
                ]);
            }
        }

        // Check-in de ontem para alguns alunos
        $guamiranga1 = $studentModels['aluno.guamiranga1@gymup.test'];
        if (! Checkin::where('user_id', $guamiranga1->id)->where('checkin_date', $yesterday)->exists()) {
            Checkin::create([
                'user_id'      => $guamiranga1->id,
                'gym_id'       => $gymGuamiranga->id,
                'checkin_date' => $yesterday,
            ]);
        }

        // ── 11. Visitas entre filiais (para o badge Visitante no admin) ────────

        // aluno.guamiranga1 treinou em Prudentópolis → aparece como Visitante no admin de Prude
        $guamiranga1 = $studentModels['aluno.guamiranga1@gymup.test'];
        $existsVisit1 = WorkoutSession::where('user_id', $guamiranga1->id)
            ->where('checkin_gym_id', $gymPrudentopolis->id)
            ->exists();
        if (! $existsVisit1) {
            WorkoutSession::create([
                'user_id'        => $guamiranga1->id,
                'gym_id'         => $gymGuamiranga->id,
                'checkin_gym_id' => $gymPrudentopolis->id,
                'started_at'     => Carbon::now()->subDay()->subHours(2),
                'finished_at'    => Carbon::now()->subDay(),
                'progress'       => 100,
                'points_granted' => true,
            ]);
        }

        // aluno.prude1 treinou em Malharte → aparece como Visitante no admin de Malharte
        $prude1 = $studentModels['aluno.prude1@gymup.test'];
        $existsVisit2 = WorkoutSession::where('user_id', $prude1->id)
            ->where('checkin_gym_id', $gymMalharte->id)
            ->exists();
        if (! $existsVisit2) {
            WorkoutSession::create([
                'user_id'        => $prude1->id,
                'gym_id'         => $gymPrudentopolis->id,
                'checkin_gym_id' => $gymMalharte->id,
                'started_at'     => Carbon::now()->subDays(2)->subHours(2),
                'finished_at'    => Carbon::now()->subDays(2),
                'progress'       => 100,
                'points_granted' => true,
            ]);
        }

        // ── Roles e permissões ────────────────────────────────────────────────
        // Garante que todos os usuários criados acima tenham roles vinculados.
        $this->call(RolesAndPermissionsSeeder::class);

        // ── Resumo ────────────────────────────────────────────────────────────

        $this->printSummary();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function upsertGym(string $name, array $attrs): Gym
    {
        $gym = Gym::firstOrCreate(['name' => $name], $attrs);

        // Garante atributos atualizados em caso de re-execução
        $dirty = [];
        foreach ($attrs as $k => $v) {
            if ($gym->$k != $v) $dirty[$k] = $v;
        }
        if ($dirty) $gym->update($dirty);

        return $gym->fresh();
    }

    private function attachGym(User $trainer, int $gymId, bool $isPrimary): void
    {
        if (! $trainer->gyms()->where('gyms.id', $gymId)->exists()) {
            $trainer->gyms()->attach($gymId, [
                'is_primary' => $isPrimary,
                'created_at' => now(),
            ]);
        }
    }

    private function printSummary(): void
    {
        $lines = [
            '====================================',
            'NETWORK TEST SEEDER — LOGINS',
            '====================================',
            'SUPER ADMIN',
            '  super@gymup.test / password',
            '',
            'NETWORK ADMIN (Rede: TNT Academias)',
            '  network@gymup.test / password',
            '',
            'GYM ADMINS',
            '  admin.guamiranga@gymup.test / password   (TNT Guamiranga)',
            '  admin.prude@gymup.test / password        (TNT Prudentópolis)',
            '  admin.malharte@gymup.test / password     (TNT Malharte)',
            '  admin.independente@gymup.test / password (Academia Independente)',
            '',
            'TRAINERS',
            '  trainer.triplo@gymup.test / password     (Guamiranga + Prude + Malharte)',
            '  trainer.simples@gymup.test / password    (Guamiranga)',
            '',
            'ALUNOS',
            '  aluno.guamiranga1@gymup.test / password  (TNT Guamiranga — visitante em Prude)',
            '  aluno.guamiranga2@gymup.test / password  (TNT Guamiranga)',
            '  aluno.prude1@gymup.test / password       (TNT Prudentópolis — visitante em Malharte)',
            '  aluno.prude2@gymup.test / password       (TNT Prudentópolis)',
            '  aluno.malharte1@gymup.test / password    (TNT Malharte)',
            '  aluno.independente@gymup.test / password (Academia Independente)',
            '====================================',
        ];

        foreach ($lines as $line) {
            $this->command->info($line);
        }
    }
}
