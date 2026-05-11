<?php

namespace App\Services;

use App\Models\ChallengeParticipant;
use App\Models\ChallengeWeeklyRanking;
use App\Models\GymChallenge;
use App\Models\User;
use App\Models\WorkoutSession;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class ChallengeService
{
    public function __construct(private PointService $pointService) {}

    // ──────────────────────────────────────────────────────────────────────────
    // Public API
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Retorna o desafio comunitário ativo da academia (1 por vez).
     */
    public function getActiveCommunityChallenge(int $gymId): ?GymChallenge
    {
        $today = now()->toDateString();

        return GymChallenge::where('gym_id', $gymId)
            ->where('scope', 'community')
            ->where('status', 'active')
            ->where('starts_at', '<=', $today)
            ->where('ends_at', '>=', $today)
            ->first();
    }

    /**
     * Retorna todos os desafios pessoais ativos da academia (podem existir vários).
     */
    public function getActivePersonalChallenges(int $gymId): \Illuminate\Database\Eloquent\Collection
    {
        $today = now()->toDateString();

        return GymChallenge::where('gym_id', $gymId)
            ->where('scope', 'personal')
            ->where('status', 'active')
            ->where('starts_at', '<=', $today)
            ->where('ends_at', '>=', $today)
            ->get();
    }

    /**
     * Alias para manter compatibilidade com código que usa getActiveChallenge().
     * Retorna o desafio comunitário ativo.
     */
    public function getActiveChallenge(int $gymId): ?GymChallenge
    {
        return $this->getActiveCommunityChallenge($gymId);
    }

    /**
     * Chamado após um treino válido (points_granted = true).
     * Processa o desafio comunitário ativo e todos os desafios pessoais ativos do aluno.
     *
     * @return array{community: ?array{challenge: GymChallenge, simple_goal_just_completed: bool}, personal: list<array{challenge: GymChallenge, simple_goal_just_completed: bool}>}
     */
    public function processValidWorkout(User $user, WorkoutSession $session): array
    {
        $sessionDate = $session->finished_at->toDateString();

        $communityResult = null;
        $personalResults = [];

        // Desafio comunitário ativo
        $community = $this->getActiveCommunityChallenge($user->gym_id);
        if ($community && $this->sessionInPeriod($sessionDate, $community)) {
            $communityResult = $this->processChallengeForWorkout($community, $user, $session);
        }

        // Desafios pessoais ativos (podem ser vários)
        foreach ($this->getActivePersonalChallenges($user->gym_id) as $personal) {
            if ($this->sessionInPeriod($sessionDate, $personal)) {
                $personalResults[] = $this->processChallengeForWorkout($personal, $user, $session);
            }
        }

        return [
            'community' => $communityResult,
            'personal'  => $personalResults,
        ];
    }

    /**
     * Retorna os dados do desafio com o progresso do aluno autenticado.
     * Funciona para qualquer escopo (community ou personal).
     */
    public function getChallengeData(GymChallenge $challenge, User $user): array
    {
        $this->finalizeCompletedWeeks($challenge);

        $participant = $this->getOrCreateParticipant($challenge, $user);

        $base = [
            'id'          => $challenge->id,
            'type'        => $challenge->type,
            'name'        => $challenge->name,
            'description' => $challenge->description,
            'starts_at'   => $challenge->starts_at->toDateString(),
            'ends_at'     => $challenge->ends_at->toDateString(),
            'status'      => $challenge->status,
        ];

        if ($challenge->isCompetitive()) {
            $weekStart = Carbon::now()->startOfWeek(Carbon::MONDAY)->toDateString();

            $currentWeek        = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
                ->where('user_id', $user->id)
                ->where('week_start', $weekStart)
                ->first();

            $myWorkoutsThisWeek = $currentWeek?->workouts_count ?? 0;
            $myTotalPoints      = $participant->total_challenge_points;

            // Só exibe posição se o aluno já tem alguma atividade no desafio.
            // Caso contrário seria "1º lugar" para quem nunca treinou.
            $myPosition = ($myTotalPoints > 0 || $myWorkoutsThisWeek > 0)
                ? ChallengeParticipant::where('challenge_id', $challenge->id)
                    ->where('total_challenge_points', '>', $myTotalPoints)
                    ->count() + 1
                : null;

            return array_merge($base, [
                'min_weekly_workouts'   => $challenge->min_weekly_workouts,
                'max_weekly_workouts'   => $challenge->max_weekly_workouts,
                'weekly_points_config'  => $this->getEffectiveScoringTable($challenge),
                'my_total_points'       => $myTotalPoints,
                'my_workouts_this_week' => $myWorkoutsThisWeek,
                'my_position'           => $myPosition,
            ]);
        }

        return array_merge($base, [
            'goal_workouts'     => $challenge->goal_workouts,
            'reward_points'     => $challenge->reward_points,
            'my_workouts'       => $participant->workouts_this_challenge,
            'goal_completed'    => $participant->goal_completed,
            'goal_completed_at' => $participant->goal_completed_at?->toIso8601String(),
        ]);
    }

    /**
     * Retorna o ranking do desafio.
     *
     * Competitivo → ranking geral por pontos acumulados.
     * Simples     → lista de participantes ordenada por progresso.
     */
    public function getRanking(GymChallenge $challenge): array
    {
        $this->finalizeCompletedWeeks($challenge);

        if ($challenge->isCompetitive()) {
            return ChallengeParticipant::where('challenge_id', $challenge->id)
                ->with('user:id,name')
                ->orderByDesc('total_challenge_points')
                ->get()
                ->values()
                ->map(fn ($p, $i) => [
                    'position'     => $i + 1,
                    'user_id'      => $p->user_id,
                    'user_name'    => $p->user->name,
                    'total_points' => $p->total_challenge_points,
                ])
                ->all();
        }

        return ChallengeParticipant::where('challenge_id', $challenge->id)
            ->with('user:id,name')
            ->orderByDesc('workouts_this_challenge')
            ->get()
            ->map(fn ($p) => [
                'user_id'        => $p->user_id,
                'user_name'      => $p->user->name,
                'workouts'       => $p->workouts_this_challenge,
                'goal_completed' => $p->goal_completed,
            ])
            ->values()
            ->all();
    }

    /**
     * Retorna o ranking semanal de uma semana específica (competitivo).
     */
    public function getWeeklyRanking(GymChallenge $challenge, string $weekStart): array
    {
        return ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('week_start', $weekStart)
            ->with('user:id,name')
            ->orderByDesc('workouts_count')
            ->get()
            ->map(fn ($r) => [
                'user_id'        => $r->user_id,
                'user_name'      => $r->user->name,
                'workouts_count' => $r->workouts_count,
                'position'       => $r->position,
                'points_awarded' => $r->points_awarded,
                'finalized'      => $r->finalized,
            ])
            ->values()
            ->all();
    }

    /**
     * Finaliza todas as semanas concluídas do desafio competitivo (lazy).
     * Uma semana está concluída quando seu domingo já passou.
     */
    public function finalizeCompletedWeeks(GymChallenge $challenge): void
    {
        if (!$challenge->isCompetitive()) {
            return;
        }

        $currentWeekStart = Carbon::now()->startOfWeek(Carbon::MONDAY)->toDateString();

        // Busca semanas anteriores à corrente que ainda não foram finalizadas
        $weekStarts = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('finalized', false)
            ->where('week_start', '<', $currentWeekStart)
            ->distinct()
            ->pluck('week_start');

        foreach ($weekStarts as $weekStart) {
            $this->finalizeWeek($challenge, Carbon::parse($weekStart)->toDateString());
        }
    }

    /**
     * Atribui o desafio a todos os alunos ativos da academia (role = 'user').
     * Chamado ao criar um desafio para garantir que todos os alunos já existentes
     * tenham um registro de participação desde o início.
     * Seguro para executar múltiplas vezes (insertOrIgnore).
     */
    public function assignToAllStudents(GymChallenge $challenge): void
    {
        $studentIds = User::where('gym_id', $challenge->gym_id)
            ->where('role', 'user')
            ->pluck('id');

        if ($studentIds->isEmpty()) {
            return;
        }

        $now  = now();
        $rows = $studentIds->map(fn ($id) => [
            'challenge_id'            => $challenge->id,
            'user_id'                 => $id,
            'gym_id'                  => $challenge->gym_id,
            'total_challenge_points'  => 0,
            'workouts_this_challenge' => 0,
            'goal_completed'          => false,
            'reward_granted'          => false,
            'created_at'              => $now,
            'updated_at'              => $now,
        ])->toArray();

        ChallengeParticipant::insertOrIgnore($rows);
    }

    /**
     * Atribui ao novo aluno o desafio comunitário ativo (se houver)
     * e todos os desafios pessoais ativos da academia.
     * Chamado no registro para garantir que o aluno entre nos desafios correntes.
     */
    public function assignActiveChallengeTo(User $user): void
    {
        $community = $this->getActiveCommunityChallenge($user->gym_id);
        if ($community) {
            $this->getOrCreateParticipant($community, $user);
        }

        foreach ($this->getActivePersonalChallenges($user->gym_id) as $personal) {
            $this->getOrCreateParticipant($personal, $user);
        }
    }

    /**
     * Encontra ou cria o registro de participação do aluno no desafio.
     */
    public function getOrCreateParticipant(GymChallenge $challenge, User $user): ChallengeParticipant
    {
        return ChallengeParticipant::firstOrCreate(
            ['challenge_id' => $challenge->id, 'user_id' => $user->id],
            [
                'gym_id'                  => $user->gym_id,
                'total_challenge_points'  => 0,
                'workouts_this_challenge' => 0,
            ]
        );
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Processa um único desafio (community ou personal) para um treino válido.
     */
    private function processChallengeForWorkout(
        GymChallenge  $challenge,
        User          $user,
        WorkoutSession $session,
    ): array {
        $simpleGoalJustCompleted = false;

        DB::transaction(function () use ($challenge, $user, $session, &$simpleGoalJustCompleted) {
            $participant = $this->getOrCreateParticipant($challenge, $user);

            if ($challenge->isCompetitive()) {
                $this->processCompetitiveWorkout($challenge, $user, $session);
            } else {
                $simpleGoalJustCompleted = $this->processSimpleWorkout($challenge, $user, $participant);
            }
        });

        $this->finalizeCompletedWeeks($challenge);

        return [
            'challenge'                  => $challenge,
            'simple_goal_just_completed' => $simpleGoalJustCompleted,
        ];
    }

    private function sessionInPeriod(string $sessionDate, GymChallenge $challenge): bool
    {
        return $sessionDate >= $challenge->starts_at->toDateString()
            && $sessionDate <= $challenge->ends_at->toDateString();
    }

    /**
     * Registra treino no ranking semanal do desafio competitivo.
     * Idempotente: não ultrapassa o limite max_weekly_workouts.
     * Não contabiliza sessão que já foi contada no mesmo dia (um treino válido por dia).
     */
    private function processCompetitiveWorkout(
        GymChallenge  $challenge,
        User          $user,
        WorkoutSession $session
    ): void {
        $weekStart = Carbon::parse($session->finished_at)
            ->startOfWeek(Carbon::MONDAY)
            ->toDateString();

        $ranking = ChallengeWeeklyRanking::firstOrCreate(
            ['challenge_id' => $challenge->id, 'user_id' => $user->id, 'week_start' => $weekStart],
            ['workouts_count' => 0, 'finalized' => false, 'points_awarded' => 0]
        );

        // Semana já finalizada → não altera
        if ($ranking->finalized) {
            return;
        }

        $max = (int) ($challenge->max_weekly_workouts ?? PHP_INT_MAX);

        if ($ranking->workouts_count < $max) {
            $ranking->increment('workouts_count');
        }
    }

    /**
     * Incrementa progresso do aluno no desafio simples.
     * Quando a meta é atingida, concede os pontos de recompensa (idempotente).
     */
    private function processSimpleWorkout(
        GymChallenge        $challenge,
        User                $user,
        ChallengeParticipant $participant
    ): bool {
        if ($participant->goal_completed) {
            return false;
        }

        $participant->increment('workouts_this_challenge');
        $participant->refresh();

        if ($participant->workouts_this_challenge >= (int) $challenge->goal_workouts) {
            $participant->update([
                'goal_completed'    => true,
                'goal_completed_at' => now(),
            ]);

            if (!$participant->reward_granted
                && $challenge->reward_type === 'points'
                && (int) ($challenge->reward_points ?? 0) > 0) {
                $this->pointService->earnPoints(
                    $user,
                    (int) $challenge->reward_points,
                    "Desafio concluído: {$challenge->name}",
                    'challenge',
                    $challenge->id
                );

                $participant->update(['reward_granted' => true]);
            }

            return true;
        }

        return false;
    }

    /**
     * Retorna a tabela de pontuação efetiva do desafio.
     * Usa weekly_points_config se definida pelo gestor; caso contrário aplica
     * a tabela padrão comprimida (evita "runaway leader"):
     *   1→10, 2→8, 3→6, 4→5, 5→4, 6→3, 7→2, 8→1, demais→0
     */
    private function getEffectiveScoringTable(GymChallenge $challenge): array
    {
        $config = $challenge->weekly_points_config ?? [];

        if (!empty($config)) {
            return $config;
        }

        return [
            '1' => 10,
            '2' => 8,
            '3' => 6,
            '4' => 5,
            '5' => 4,
            '6' => 3,
            '7' => 2,
            '8' => 1,
        ];
    }

    /**
     * Finaliza o ranking de uma semana passada:
     *   - Atribui posições (apenas alunos que atingiram min_weekly_workouts)
     *   - Concede pontos conforme getEffectiveScoringTable()
     *   - Acumula pontos em challenge_participants.total_challenge_points
     *   - Marca registros como finalized = true
     *
     * Em caso de empate (mesmo workouts_count), os alunos compartilham a mesma posição
     * e o próximo bloco recebe a posição seguinte ao número total de empatados.
     * Posições fora da tabela recebem 0 pontos.
     */
    private function finalizeWeek(GymChallenge $challenge, string $weekStart): void
    {
        $minWorkouts  = (int) ($challenge->min_weekly_workouts ?? 1);
        $pointsConfig = $this->getEffectiveScoringTable($challenge);

        $entries = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('week_start', $weekStart)
            ->where('finalized', false)
            ->orderByDesc('workouts_count')
            ->get();

        $position  = 1;
        $prevCount = null;
        $prevPos   = 1;

        foreach ($entries as $entry) {
            if ($entry->workouts_count < $minWorkouts) {
                // Não atingiu o mínimo — finaliza sem posição/pontos
                $entry->update(['finalized' => true]);
                continue;
            }

            // Tratamento de empate: mesma quantidade = mesma posição
            if ($prevCount !== null && $entry->workouts_count === $prevCount) {
                $assignedPos = $prevPos;
            } else {
                $assignedPos = $position;
                $prevPos     = $position;
                $prevCount   = $entry->workouts_count;
            }

            $pointsAwarded = (int) ($pointsConfig[(string) $assignedPos] ?? 0);

            $entry->update([
                'position'       => $assignedPos,
                'points_awarded' => $pointsAwarded,
                'finalized'      => true,
            ]);

            if ($pointsAwarded > 0) {
                ChallengeParticipant::where('challenge_id', $challenge->id)
                    ->where('user_id', $entry->user_id)
                    ->increment('total_challenge_points', $pointsAwarded);
            }

            $position++;
        }
    }
}
