<?php

namespace Database\Seeders;

use App\Models\ChallengeParticipant;
use App\Models\ChallengeWeeklyRanking;
use App\Models\Checkin;
use App\Models\GymChallenge;
use App\Models\User;
use App\Models\UserAchievement;
use App\Models\WorkoutSession;
use App\Services\AchievementService;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Popula dados demo com aparência realista para gravações de vídeo.
 *
 * ═══════════════════════════════════════════════════════════════════════
 * RANKINGS (período × pontos diferentes)
 * ───────────────────────────────────────────────────────────────────────
 *  Uma PointTransaction por sessão, created_at = data real da sessão.
 *  Assim os filtros de período do RankingController somam subconjuntos:
 *
 *   sessions_this_week  → Dom 15–Qua 18  (SEMANAL + MENSAL + GERAL)
 *   sessions_prev_week  → Jun 8–14       (MENSAL + GERAL)
 *   sessions_historical → Maio           (somente GERAL)
 *
 * ═══════════════════════════════════════════════════════════════════════
 * MARCOS TAQUES — REGRAS ESPECIAIS
 * ───────────────────────────────────────────────────────────────────────
 *  • Sem sessão/checkin HOJE → botão de QR funciona no demo
 *  • Exibe 2/3 treinos esta semana (meta=3, feitos=2 ontem+anteontem)
 *  • É o #1 no ranking GERAL graças ao histórico longo (12 sessões)
 *  • Conquistas desbloqueadas: primeiro_treino + 5_treinos +
 *    10_treinos + streak_3  →  100 pts bônus
 *  • Geral final: 12×30 + 100 = 460 pts
 *
 * ═══════════════════════════════════════════════════════════════════════
 * CONSISTÊNCIA CHECK-INS ↔ PONTOS
 * ───────────────────────────────────────────────────────────────────────
 *  1 sessão = 1 checkin = 30 pts de sessão (+ bônus de conquistas).
 *  "Check-ins registrados" no dashboard = total de sessões.
 *  "Pts acumulados" = sessões×30 + conquistas.  Proporção sempre coerente.
 */
class DemoWeekSeeder extends Seeder
{
    private const CHALLENGE_NAME  = 'Desafio Semana em Movimento';
    private const PTS_PER_SESSION = 30;
    private const PTS_DESCRIPTION = 'Sessão de treino';

    // ─── Ponto de entrada ────────────────────────────────────────────────────

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

                // Marcos primeiro (para pegar position=1 no desafio)
                $sorted = $students->values()->sortBy(function (User $u) {
                    return str_contains(mb_strtolower($u->name), 'marcos taques') ? 0 : 1;
                })->values();

                foreach ($sorted as $index => $student) {
                    $profile = $this->profileFor($student, $index);

                    $this->clearStudentData($student);
                    $this->seedStudentData($student, $profile);
                    $this->seedChallengeProgress($challenge, $student, $profile, $index + 1);
                }
            });
        }

        // Conquistas automáticas baseadas nas sessões e streak de cada aluno
        $achievements = app(AchievementService::class);
        User::where('role', 'user')->get()->each(
            fn (User $student) => $achievements->grantNewlyUnlocked($student)
        );

        $this->command?->info('Semana demo populada. Marcos é #1 no geral e tem o checkin de hoje em aberto.');
    }

    // ─── Perfis ──────────────────────────────────────────────────────────────

    /**
     * sessions_this_week        : sessões nesta semana (Dom 15–hoje)
     * sessions_this_week_offset : quantos dias no passado começar (0=hoje, 1=ontem…)
     *                             Use 1 para NÃO incluir hoje (Marcos)
     * sessions_prev_week        : sessões na semana anterior (Jun 8–14, mesmo mês)
     * sessions_historical       : sessões em meses anteriores (Maio)
     * streak                    : dias consecutivos (setado direto no campo)
     * goal                      : meta semanal (denominador do "2/3")
     * challenge_points          : pontos no desafio ativo
     *
     * Pontos de sessão = (this_week + prev_week + historical) × 30
     * Pontos de conquista = adicionados automaticamente por grantNewlyUnlocked()
     *
     * ── Conquistas disponíveis e quando desbloqueiam ─────────────────────
     *  first_workout  → total ≥ 1  sessão      →  10 pts
     *  five_workouts  → total ≥ 5  sessões     →  20 pts
     *  ten_workouts   → total ≥ 10 sessões     →  40 pts
     *  streak_3       → streak ≥ 3 dias        →  30 pts
     *  streak_7       → streak ≥ 7 dias        →  70 pts
     *
     * ── Totais por perfil (sessões pts + conquistas pts) ─────────────────
     *  Marcos     : 12 sess → 360 + 100 = 460 pts  (#1 geral)
     *  Perfil [0] : 7  sess → 210 +  60 = 270 pts  (#2 geral)
     *  Perfil [1] : 6  sess → 180 +  60 = 240 pts  (#3 geral)
     *  Perfil [2] : 5  sess → 150 +  60 = 210 pts
     *  Perfil [3] : 3  sess →  90 +  10 = 100 pts
     *  Perfil [4] : 2  sess →  60 +  10 =  70 pts
     *  Perfil [5] : 1  sess →  30 +  10 =  40 pts
     */
    private function profileFor(User $student, int $index): array
    {
        // ── Marcos Taques ────────────────────────────────────────────────────
        // Sem sessão hoje → checkin de hoje fica disponível para demo.
        // 12 sessões históricas → #1 no geral.  streak=3 → unlock streak_3.
        if (str_contains(mb_strtolower($student->name), 'marcos taques')) {
            return [
                'sessions_this_week'        => 2,   // Ter 17 + Seg 16
                'sessions_this_week_offset' => 1,   // começa em ontem, não hoje
                'sessions_prev_week'        => 2,   // Sáb 14 + Sex 13
                'sessions_historical'       => 8,   // 8 sessões em Maio
                'streak'                    => 3,
                'goal'                      => 3,
                'challenge_points'          => 130,
            ];
        }

        // ── Outros alunos ────────────────────────────────────────────────────
        // offset=0 → inclui hoje; histórico variado para rankings diferentes.
        $profiles = [
            // [0] 7 sess (4+2+1) · streak=4 · Weekly 120 · Mensal 180 · Geral 210 + 60 achiev = 270
            ['sessions_this_week' => 4, 'sessions_this_week_offset' => 0, 'sessions_prev_week' => 2, 'sessions_historical' => 1, 'streak' => 4, 'goal' => 5, 'challenge_points' => 100],
            // [1] 6 sess (3+2+1) · streak=3 · Weekly 90  · Mensal 150 · Geral 180 + 60 achiev = 240
            ['sessions_this_week' => 3, 'sessions_this_week_offset' => 0, 'sessions_prev_week' => 2, 'sessions_historical' => 1, 'streak' => 3, 'goal' => 5, 'challenge_points' =>  90],
            // [2] 5 sess (3+2+0) · streak=3 · Weekly 90  · Mensal 150 · Geral 150 + 60 achiev = 210
            ['sessions_this_week' => 3, 'sessions_this_week_offset' => 0, 'sessions_prev_week' => 2, 'sessions_historical' => 0, 'streak' => 3, 'goal' => 4, 'challenge_points' =>  80],
            // [3] 3 sess (2+1+0) · streak=2 · Weekly 60  · Mensal 90  · Geral  90 + 10 achiev = 100
            ['sessions_this_week' => 2, 'sessions_this_week_offset' => 0, 'sessions_prev_week' => 1, 'sessions_historical' => 0, 'streak' => 2, 'goal' => 4, 'challenge_points' =>  60],
            // [4] 2 sess (2+0+0) · streak=2 · Weekly 60  · Mensal 60  · Geral  60 + 10 achiev =  70
            ['sessions_this_week' => 2, 'sessions_this_week_offset' => 0, 'sessions_prev_week' => 0, 'sessions_historical' => 0, 'streak' => 2, 'goal' => 3, 'challenge_points' =>  45],
            // [5] 1 sess (1+0+0) · streak=1 · Weekly 30  · Mensal 30  · Geral  30 + 10 achiev =  40
            ['sessions_this_week' => 1, 'sessions_this_week_offset' => 0, 'sessions_prev_week' => 0, 'sessions_historical' => 0, 'streak' => 1, 'goal' => 3, 'challenge_points' =>  20],
        ];

        // index 0 é Marcos (já tratado), então shift de 1 para os demais
        return $profiles[($index > 0 ? $index - 1 : 0) % count($profiles)];
    }

    // ─── Limpeza ─────────────────────────────────────────────────────────────

    private function clearStudentData(User $student): void
    {
        WorkoutSession::where('user_id', $student->id)->delete();
        Checkin::where('user_id', $student->id)->delete();
        DB::table('point_transactions')->where('user_id', $student->id)->delete();

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

    // ─── Seed principal ───────────────────────────────────────────────────────

    private function seedStudentData(User $student, array $profile): void
    {
        $today          = Carbon::today();
        $thisWeekStart  = $today->copy()->startOfWeek(Carbon::SUNDAY); // Dom Jun 15
        $prevWeekEnd    = $thisWeekStart->copy()->subDay();             // Sáb Jun 14
        $historicalBase = $today->copy()->startOfMonth()->subDays(14); // ~Mai 18

        $offset = $profile['sessions_this_week_offset'] ?? 0;

        // ── 1. Esta semana ────────────────────────────────────────────────────
        $inserted = 0;
        for ($i = $offset; $inserted < $profile['sessions_this_week']; $i++) {
            $day = $today->copy()->subDays($i);
            if ($day->lt($thisWeekStart)) break;
            $this->insertSession($student, $day);
            $inserted++;
        }

        // ── 2. Semana anterior (dentro do mês corrente) ───────────────────────
        for ($i = 0; $i < $profile['sessions_prev_week']; $i++) {
            $this->insertSession($student, $prevWeekEnd->copy()->subDays($i));
        }

        // ── 3. Histórico (mês anterior) ───────────────────────────────────────
        for ($i = 0; $i < $profile['sessions_historical']; $i++) {
            $this->insertSession($student, $historicalBase->copy()->subDays($i * 2));
        }

        // ── 4. Streak, meta e saldo ───────────────────────────────────────────
        $totalSessions = $profile['sessions_this_week']
                       + $profile['sessions_prev_week']
                       + $profile['sessions_historical'];

        // Última sessão = primeiro dia inserido nesta semana (ontem para Marcos, hoje para outros)
        $lastWorkoutDate = $today->copy()->subDays($offset)->toDateString();

        $student->update([
            'current_streak'      => $profile['streak'],
            'weekly_streak'       => $profile['streak'],
            'best_streak'         => $profile['streak'],
            'current_week_start'  => $thisWeekStart,
            'current_week_goal'   => $profile['goal'],
            'week_goal_completed' => $profile['sessions_this_week'] >= $profile['goal'],
            'last_workout_date'   => $lastWorkoutDate,
            // Pontos de sessão apenas — conquistas serão somadas por grantNewlyUnlocked()
            'points_balance'      => $totalSessions * self::PTS_PER_SESSION,
        ]);
    }

    /**
     * 1 checkin + 1 WorkoutSession + 1 PointTransaction (30 pts)
     * com datas retroativas reais.
     */
    private function insertSession(User $student, Carbon $day): void
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

        // DB::table para poder setar created_at retroativo
        // (created_at não está em $fillable do model PointTransaction)
        DB::table('point_transactions')->insert([
            'user_id'     => $student->id,
            'gym_id'      => $student->gym_id,
            'type'        => 'earn',
            'category'    => 'workout',
            'points'      => self::PTS_PER_SESSION,
            'description' => self::PTS_DESCRIPTION,
            'created_at'  => $finishedAt->toDateTimeString(),
            'updated_at'  => $finishedAt->toDateTimeString(),
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
                'description'         => 'Ranking demo de consistência: quem treinar mais vezes na semana sobe no pódio.',
                'starts_at'           => Carbon::today()->subDays(6),
                'ends_at'             => Carbon::today()->addDays(7),
                'status'              => 'active',
                'reward_type'         => 'points',
                'reward_description'  => 'Bônus de 120 pontos para o primeiro lugar',
                'min_weekly_workouts' => 1,
                'max_weekly_workouts' => 7,
                'weekly_points_config'=> ['1' => 130, '2' => 100, '3' => 90, '4' => 65, '5' => 50, '6' => 25, '7' => 10],
            ]
        );
    }

    private function seedChallengeProgress(
        GymChallenge $challenge,
        User         $student,
        array        $profile,
        int          $position
    ): void {
        $totalSessions = $profile['sessions_this_week']
                       + $profile['sessions_prev_week']
                       + $profile['sessions_historical'];

        ChallengeParticipant::updateOrCreate(
            ['challenge_id' => $challenge->id, 'user_id' => $student->id],
            [
                'gym_id'                  => $student->gym_id,
                'total_challenge_points'  => $profile['challenge_points'],
                'workouts_this_challenge' => $totalSessions,
                'goal_completed'          => false,
                'reward_granted'          => false,
            ]
        );

        ChallengeWeeklyRanking::updateOrCreate(
            [
                'challenge_id' => $challenge->id,
                'user_id'      => $student->id,
                'week_start'   => Carbon::today()->startOfWeek(Carbon::MONDAY)->toDateString(),
            ],
            [
                'workouts_count' => $profile['sessions_this_week'],
                'position'       => $position,   // Marcos sempre é index 0 → position 1
                'points_awarded' => 0,
                'finalized'      => false,
            ]
        );
    }
}
