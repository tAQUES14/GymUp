<?php

namespace Database\Seeders;

use App\Models\ChallengeParticipant;
use App\Models\ChallengeWeeklyRanking;
use App\Models\Checkin;
use App\Models\GymChallenge;
use App\Models\PointTransaction;
use App\Models\User;
use App\Models\UserAchievement;
use App\Models\WorkoutSession;
use App\Services\AchievementService;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DemoWeekSeeder extends Seeder
{
    private const CHALLENGE_NAME = 'Desafio Semana em Movimento';
    private const POINTS_DESCRIPTION = 'Carga demo: semana de treinos';

    public function run(): void
    {
        $this->call(AchievementSeeder::class);

        $studentsByGym = User::query()
            ->where('role', 'user')
            ->orderBy('gym_id')
            ->orderBy('name')
            ->get()
            ->groupBy('gym_id');

        foreach ($studentsByGym as $gymId => $students) {
            DB::transaction(function () use ($gymId, $students) {
                $challenge = $this->upsertChallenge((int) $gymId);

                foreach ($students->values() as $index => $student) {
                    $profile = $this->profileFor($student, $index);

                    $this->clearStudentData($student);
                    $this->seedStudentWeek($student, $profile);
                    $this->seedChallengeProgress($challenge, $student, $profile, $index + 1);
                }
            });
        }

        $achievements = app(AchievementService::class);
        User::where('role', 'user')->get()->each(
            fn (User $student) => $achievements->grantNewlyUnlocked($student)
        );

        $this->command?->info('Semana demo populada para todos os alunos atuais.');
    }

    // ─── Perfis ──────────────────────────────────────────────────────────────

    /**
     * workouts_this_week : sessões criadas de hoje para trás dentro da semana atual (Dom–Qua = máx 4)
     * workouts_prev_week : sessões adicionais criadas na semana anterior (para streak e total de checkins)
     * points             : saldo total de pontos após seed
     * streak             : dias consecutivos (setado direto no campo)
     * goal               : meta semanal
     * challenge_points   : pontos no desafio ativo
     */
    private function profileFor(User $student, int $index): array
    {
        if (str_contains(mb_strtolower($student->name), 'marcos taques')) {
            return [
                'workouts_this_week' => 2,
                'workouts_prev_week' => 0,
                'points'             => 150,
                'streak'             => 2,
                'goal'               => 3,
                'challenge_points'   => 75,
            ];
        }

        // Máximo de 4 treinos esta semana (Dom 15 → Qua 18 = 4 dias disponíveis)
        $profiles = [
            // 7 checkins total (4 esta semana + 3 semana anterior) — aluno mais dedicado
            ['workouts_this_week' => 4, 'workouts_prev_week' => 3, 'points' => 210, 'streak' => 7, 'goal' => 5, 'challenge_points' => 120],
            // 6 checkins (3 + 3)
            ['workouts_this_week' => 3, 'workouts_prev_week' => 3, 'points' => 180, 'streak' => 4, 'goal' => 5, 'challenge_points' => 100],
            // 5 checkins (3 + 2)
            ['workouts_this_week' => 3, 'workouts_prev_week' => 2, 'points' => 150, 'streak' => 3, 'goal' => 4, 'challenge_points' =>  90],
            // 4 checkins (2 + 2)
            ['workouts_this_week' => 2, 'workouts_prev_week' => 2, 'points' => 110, 'streak' => 2, 'goal' => 4, 'challenge_points' =>  65],
            // 2 checkins (2 + 0)
            ['workouts_this_week' => 2, 'workouts_prev_week' => 0, 'points' =>  85, 'streak' => 2, 'goal' => 3, 'challenge_points' =>  50],
            // 1 checkin
            ['workouts_this_week' => 1, 'workouts_prev_week' => 0, 'points' =>  45, 'streak' => 1, 'goal' => 3, 'challenge_points' =>  25],
        ];

        return $profiles[$index % count($profiles)];
    }

    // ─── Limpeza ──────────────────────────────────────────────────────────────

    /**
     * Remove todos os dados do aluno para garantir seed limpo e consistente.
     */
    private function clearStudentData(User $student): void
    {
        WorkoutSession::where('user_id', $student->id)->delete();
        Checkin::where('user_id', $student->id)->delete();
        PointTransaction::where('user_id', $student->id)->delete();

        if (class_exists(UserAchievement::class)) {
            UserAchievement::where('user_id', $student->id)->delete();
        }

        $student->update([
            'points_balance'      => 0,
            'current_streak'      => 0,
            'weekly_streak'       => 0,
            'best_streak'         => 0,
            'last_workout_date'   => null,
            'week_goal_completed' => false,
        ]);
    }

    // ─── Seed da semana ──────────────────────────────────────────────────────

    private function seedStudentWeek(User $student, array $profile): void
    {
        $today         = Carbon::today();
        // Semana atual começa no Domingo (alinhado com o backend)
        $thisWeekStart = $today->copy()->startOfWeek(Carbon::SUNDAY);
        // Semana anterior: Dom anterior → Sáb anterior
        $prevWeekEnd   = $thisWeekStart->copy()->subDay();          // Sáb da semana passada
        $weekStart     = $today->copy()->startOfWeek(Carbon::MONDAY); // para current_week_start

        // ── 1. Sessões desta semana (de hoje para trás, dentro da semana) ──
        for ($offset = 0; $offset < $profile['workouts_this_week']; $offset++) {
            $day = $today->copy()->subDays($offset);
            if ($day->lt($thisWeekStart)) break; // não sair da semana atual
            $this->createSession($student, $day);
        }

        // ── 2. Sessões da semana anterior (do Sáb para trás) ─────────────
        for ($offset = 0; $offset < $profile['workouts_prev_week']; $offset++) {
            $day = $prevWeekEnd->copy()->subDays($offset);
            $this->createSession($student, $day);
        }

        // ── 3. Atualizar streak e meta ────────────────────────────────────
        $goalMet = $profile['workouts_this_week'] >= $profile['goal'];

        $student->update([
            'weekly_streak'       => $profile['streak'],
            'current_streak'      => $profile['streak'],
            'best_streak'         => $profile['streak'],
            'current_week_start'  => $thisWeekStart,
            'current_week_goal'   => $profile['goal'],
            'week_goal_completed' => $goalMet,
            'last_workout_date'   => $today->toDateString(),
        ]);

        // ── 4. Pontos (saldo = exatamente o valor do perfil) ──────────────
        PointTransaction::create([
            'user_id'     => $student->id,
            'gym_id'      => $student->gym_id,
            'type'        => 'earn',
            'category'    => 'demo',
            'points'      => $profile['points'],
            'description' => self::POINTS_DESCRIPTION,
        ]);

        $student->update(['points_balance' => $profile['points']]);
    }

    private function createSession(User $student, Carbon $day): void
    {
        $startedAt  = $day->copy()->setTime(18, 10);
        $finishedAt = $day->copy()->setTime(19, 5);

        Checkin::create([
            'user_id'       => $student->id,
            'gym_id'        => $student->gym_id,
            'checkin_date'  => $day->toDateString(),
            'checked_in_at' => $startedAt,
        ]);

        WorkoutSession::create([
            'user_id'           => $student->id,
            'gym_id'            => $student->gym_id,
            'checkin_gym_id'    => $student->gym_id,
            'started_at'        => $startedAt,
            'finished_at'       => $finishedAt,
            'progress'          => 100,
            'is_valid'          => true,
            'counts_for_points' => true,
            'counts_for_streak' => true,
            'points_granted'    => true,
            'points_granted_at' => $finishedAt,
        ]);
    }

    // ─── Desafio ─────────────────────────────────────────────────────────────

    private function upsertChallenge(int $gymId): GymChallenge
    {
        return GymChallenge::updateOrCreate(
            ['gym_id' => $gymId, 'name' => self::CHALLENGE_NAME],
            [
                'type'                => 'competitive',
                'scope'               => 'community',
                'description'         => 'Ranking demo de consistencia: quem treinar mais vezes na semana sobe no podio.',
                'starts_at'           => Carbon::today()->subDays(6),
                'ends_at'             => Carbon::today()->addDays(7),
                'status'              => 'active',
                'reward_type'         => 'points',
                'reward_description'  => 'Bonus de 120 pontos para o primeiro lugar',
                'min_weekly_workouts' => 1,
                'max_weekly_workouts' => 7,
                'weekly_points_config'=> ['1' => 120, '2' => 100, '3' => 90, '4' => 65, '5' => 50, '6' => 25],
            ]
        );
    }

    private function seedChallengeProgress(GymChallenge $challenge, User $student, array $profile, int $position): void
    {
        $totalWorkouts = $profile['workouts_this_week'] + $profile['workouts_prev_week'];

        ChallengeParticipant::updateOrCreate(
            ['challenge_id' => $challenge->id, 'user_id' => $student->id],
            [
                'gym_id'                   => $student->gym_id,
                'total_challenge_points'   => $profile['challenge_points'],
                'workouts_this_challenge'  => $totalWorkouts,
                'goal_completed'           => false,
                'reward_granted'           => false,
            ]
        );

        ChallengeWeeklyRanking::updateOrCreate(
            [
                'challenge_id' => $challenge->id,
                'user_id'      => $student->id,
                'week_start'   => Carbon::today()->startOfWeek(Carbon::MONDAY)->toDateString(),
            ],
            [
                'workouts_count' => $profile['workouts_this_week'],
                'position'       => $position,
                'points_awarded' => 0,
                'finalized'      => false,
            ]
        );
    }
}
