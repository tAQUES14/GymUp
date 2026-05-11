<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Checkin;
use App\Models\ChallengeParticipant;
use App\Models\ChallengeWeeklyRanking;
use App\Models\Gym;
use App\Models\GymChallenge;
use App\Models\User;
use App\Models\WorkoutSession;
use App\Services\ChallengeService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

class ChallengeTest extends TestCase
{
    use RefreshDatabase;

    // ──────────────────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────────────────

    private function createAuthUser(array $userAttrs = []): array
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(array_merge(['gym_id' => $gym->id, 'points_balance' => 0], $userAttrs));
        Sanctum::actingAs($user);

        return [$gym, $user];
    }

    private function createAdminUser(Gym $gym): User
    {
        $admin = User::factory()->create(['gym_id' => $gym->id, 'role' => 'super_admin']);
        Sanctum::actingAs($admin);

        return $admin;
    }

    /** Cria um desafio simples ativo com configurações padrão. */
    private function createSimpleChallenge(Gym $gym, array $attrs = []): GymChallenge
    {
        return GymChallenge::create(array_merge([
            'gym_id'        => $gym->id,
            'type'          => 'simple',
            'name'          => 'Desafio Simples',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'status'        => 'active',
            'goal_workouts' => 5,
            'reward_points' => 200,
        ], $attrs));
    }

    /** Cria um desafio competitivo ativo com configurações padrão. */
    private function createCompetitiveChallenge(Gym $gym, array $attrs = []): GymChallenge
    {
        return GymChallenge::create(array_merge([
            'gym_id'               => $gym->id,
            'type'                 => 'competitive',
            'name'                 => 'Desafio Competitivo',
            'starts_at'            => now()->toDateString(),
            'ends_at'              => now()->addDays(28)->toDateString(),
            'status'               => 'active',
            'min_weekly_workouts'  => 2,
            'max_weekly_workouts'  => 5,
            'weekly_points_config' => ['1' => 100, '2' => 80, '3' => 60],
        ], $attrs));
    }

    /**
     * Simula um treino válido (com pontos) para um usuário.
     * Cria checkin + sessão e chama o ChallengeService diretamente.
     */
    private function grantValidWorkout(User $user, Gym $gym, Carbon $at = null): WorkoutSession
    {
        $at = $at ?? now();

        Checkin::firstOrCreate([
            'user_id'      => $user->id,
            'gym_id'       => $gym->id,
            'checkin_date' => $at->toDateString(),
        ]);

        $session = WorkoutSession::create([
            'user_id'           => $user->id,
            'gym_id'            => $gym->id,
            'started_at'        => $at->copy()->subMinutes(20),
            'finished_at'       => $at,
            'progress'          => 80,
            'points_granted'    => true,
            'points_granted_at' => $at,
        ]);

        app(ChallengeService::class)->processValidWorkout($user, $session);

        return $session;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Desafio Simples — testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function simple_challenge_tracks_workout_progress()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();
        $challenge    = $this->createSimpleChallenge($gym, ['goal_workouts' => 3]);

        $this->grantValidWorkout($user, $gym);

        $participant = ChallengeParticipant::where('challenge_id', $challenge->id)
            ->where('user_id', $user->id)
            ->first();

        $this->assertNotNull($participant);
        $this->assertEquals(1, $participant->workouts_this_challenge);
        $this->assertFalse($participant->goal_completed);

        Carbon::setTestNow();
    }

    /** @test */
    public function simple_challenge_grants_reward_on_goal_completion()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();
        $challenge    = $this->createSimpleChallenge($gym, ['goal_workouts' => 2, 'reward_points' => 200]);

        $this->grantValidWorkout($user, $gym, now());
        $this->grantValidWorkout($user, $gym, now()->addHours(2));

        $participant = ChallengeParticipant::where('challenge_id', $challenge->id)
            ->where('user_id', $user->id)
            ->first();

        $this->assertTrue($participant->goal_completed);
        $this->assertTrue($participant->reward_granted);

        $user->refresh();
        $this->assertEquals(200, $user->points_balance);

        Carbon::setTestNow();
    }

    /** @test */
    public function simple_challenge_reward_is_idempotent()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();
        $challenge    = $this->createSimpleChallenge($gym, ['goal_workouts' => 1, 'reward_points' => 100]);

        // Primeiro treino conclui o desafio
        $this->grantValidWorkout($user, $gym, now());

        // Treinos adicionais não devem re-conceder a recompensa
        $this->grantValidWorkout($user, $gym, now()->addDays(1));
        $this->grantValidWorkout($user, $gym, now()->addDays(2));

        $user->refresh();
        $this->assertEquals(100, $user->points_balance);

        Carbon::setTestNow();
    }

    /** @test */
    public function simple_challenge_api_returns_progress()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();
        $this->createSimpleChallenge($gym, ['goal_workouts' => 5]);

        $this->grantValidWorkout($user, $gym);
        $this->grantValidWorkout($user, $gym, now()->addHours(2));

        $response = $this->getJson('/api/challenges/active');

        $response->assertStatus(200);
        $response->assertJsonPath('challenge.type', 'simple');
        $response->assertJsonPath('challenge.my_workouts', 2);
        $response->assertJsonPath('challenge.goal_completed', false);

        Carbon::setTestNow();
    }

    /** @test */
    public function no_active_challenge_returns_null()
    {
        [$gym, $user] = $this->createAuthUser();

        $response = $this->getJson('/api/challenges/active');

        $response->assertStatus(200);
        $response->assertJsonPath('challenge', null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Desafio Competitivo — testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function competitive_challenge_tracks_weekly_workouts()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();
        $challenge    = $this->createCompetitiveChallenge($gym, ['max_weekly_workouts' => 5]);

        $this->grantValidWorkout($user, $gym, now());
        $this->grantValidWorkout($user, $gym, now()->addHours(2));
        $this->grantValidWorkout($user, $gym, now()->addHours(4));

        $weekStart = Carbon::now()->startOfWeek(Carbon::MONDAY)->toDateString();
        $ranking   = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('user_id', $user->id)
            ->where('week_start', $weekStart)
            ->first();

        $this->assertNotNull($ranking);
        $this->assertEquals(3, $ranking->workouts_count);

        Carbon::setTestNow();
    }

    /** @test */
    public function competitive_challenge_caps_workouts_at_max()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();
        $challenge    = $this->createCompetitiveChallenge($gym, ['max_weekly_workouts' => 3]);

        // 5 treinos — apenas 3 devem ser contabilizados
        for ($i = 0; $i < 5; $i++) {
            $this->grantValidWorkout($user, $gym, now()->addHours($i));
        }

        $weekStart = Carbon::now()->startOfWeek(Carbon::MONDAY)->toDateString();
        $ranking   = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('user_id', $user->id)
            ->where('week_start', $weekStart)
            ->first();

        $this->assertEquals(3, $ranking->workouts_count);

        Carbon::setTestNow();
    }

    /** @test */
    public function competitive_challenge_finalizes_week_and_assigns_points()
    {
        // Simulamos a semana passada
        $lastMonday = Carbon::now()->startOfWeek(Carbon::MONDAY)->subWeek();
        Carbon::setTestNow($lastMonday->copy()->addDays(2)); // quarta-feira passada

        [$gym, $user1] = $this->createAuthUser();
        $challenge     = $this->createCompetitiveChallenge($gym, [
            'starts_at'           => $lastMonday->toDateString(),
            'min_weekly_workouts' => 2,
            'max_weekly_workouts' => 5,
        ]);

        $user2 = User::factory()->create(['gym_id' => $gym->id, 'points_balance' => 0]);
        $user3 = User::factory()->create(['gym_id' => $gym->id, 'points_balance' => 0]);

        // user1: 4 treinos (1º lugar)
        for ($i = 0; $i < 4; $i++) {
            $this->grantValidWorkout($user1, $gym, now()->addHours($i));
        }

        // user2: 3 treinos (2º lugar)
        Sanctum::actingAs($user2);
        for ($i = 0; $i < 3; $i++) {
            $this->grantValidWorkout($user2, $gym, now()->addHours($i));
        }

        // user3: 1 treino — abaixo do mínimo de 2, não entra no ranking
        Sanctum::actingAs($user3);
        $this->grantValidWorkout($user3, $gym, now());

        // Avança para semana seguinte — a finalização lazy é acionada
        Carbon::setTestNow(Carbon::now()->startOfWeek(Carbon::MONDAY)->addWeek());

        Sanctum::actingAs($user1);
        app(ChallengeService::class)->finalizeCompletedWeeks($challenge);

        $weekStart = $lastMonday->toDateString();

        $r1 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)->where('user_id', $user1->id)->where('week_start', $weekStart)->first();
        $r2 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)->where('user_id', $user2->id)->where('week_start', $weekStart)->first();
        $r3 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)->where('user_id', $user3->id)->where('week_start', $weekStart)->first();

        // user1 → 1º, 100 pts
        $this->assertEquals(1, $r1->position);
        $this->assertEquals(100, $r1->points_awarded);
        $this->assertTrue($r1->finalized);

        // user2 → 2º, 80 pts
        $this->assertEquals(2, $r2->position);
        $this->assertEquals(80, $r2->points_awarded);
        $this->assertTrue($r2->finalized);

        // user3 → sem posição (abaixo do mínimo)
        $this->assertNull($r3->position);
        $this->assertEquals(0, $r3->points_awarded);
        $this->assertTrue($r3->finalized);

        // Pontos acumulados nos participantes
        $p1 = ChallengeParticipant::where('challenge_id', $challenge->id)->where('user_id', $user1->id)->first();
        $p2 = ChallengeParticipant::where('challenge_id', $challenge->id)->where('user_id', $user2->id)->first();

        $this->assertEquals(100, $p1->total_challenge_points);
        $this->assertEquals(80, $p2->total_challenge_points);

        Carbon::setTestNow();
    }

    /** @test */
    public function competitive_challenge_tie_shares_same_position()
    {
        $lastMonday = Carbon::now()->startOfWeek(Carbon::MONDAY)->subWeek();
        Carbon::setTestNow($lastMonday->copy()->addDays(2));

        [$gym, $user1] = $this->createAuthUser();
        $challenge     = $this->createCompetitiveChallenge($gym, [
            'starts_at'           => $lastMonday->toDateString(),
            'min_weekly_workouts' => 1,
            'max_weekly_workouts' => 5,
            'weekly_points_config' => ['1' => 100, '2' => 80, '3' => 60],
        ]);

        $user2 = User::factory()->create(['gym_id' => $gym->id, 'points_balance' => 0]);

        // Ambos com 3 treinos — empate no 1º lugar
        for ($i = 0; $i < 3; $i++) {
            $this->grantValidWorkout($user1, $gym, now()->addHours($i));
        }
        Sanctum::actingAs($user2);
        for ($i = 0; $i < 3; $i++) {
            $this->grantValidWorkout($user2, $gym, now()->addHours($i));
        }

        Carbon::setTestNow(Carbon::now()->startOfWeek(Carbon::MONDAY)->addWeek());

        app(ChallengeService::class)->finalizeCompletedWeeks($challenge);

        $weekStart = $lastMonday->toDateString();

        $r1 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)->where('user_id', $user1->id)->where('week_start', $weekStart)->first();
        $r2 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)->where('user_id', $user2->id)->where('week_start', $weekStart)->first();

        // Ambos devem ter posição 1 e 100 pontos
        $this->assertEquals(1, $r1->position);
        $this->assertEquals(1, $r2->position);
        $this->assertEquals(100, $r1->points_awarded);
        $this->assertEquals(100, $r2->points_awarded);

        Carbon::setTestNow();
    }

    /** @test */
    public function competitive_challenge_finalization_is_idempotent()
    {
        $lastMonday = Carbon::now()->startOfWeek(Carbon::MONDAY)->subWeek();
        Carbon::setTestNow($lastMonday->copy()->addDays(2));

        [$gym, $user] = $this->createAuthUser();
        $challenge    = $this->createCompetitiveChallenge($gym, [
            'starts_at' => $lastMonday->toDateString(),
            'min_weekly_workouts' => 1,
        ]);

        for ($i = 0; $i < 3; $i++) {
            $this->grantValidWorkout($user, $gym, now()->addHours($i));
        }

        Carbon::setTestNow(Carbon::now()->startOfWeek(Carbon::MONDAY)->addWeek());

        // Finalize duas vezes
        app(ChallengeService::class)->finalizeCompletedWeeks($challenge);
        app(ChallengeService::class)->finalizeCompletedWeeks($challenge);

        $p = ChallengeParticipant::where('challenge_id', $challenge->id)->where('user_id', $user->id)->first();

        // 100 pontos, não 200
        $this->assertEquals(100, $p->total_challenge_points);

        Carbon::setTestNow();
    }

    /** @test */
    public function workout_outside_challenge_period_is_ignored()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        // Desafio começa daqui a 7 dias
        $this->createSimpleChallenge($gym, [
            'starts_at' => now()->addDays(7)->toDateString(),
            'ends_at'   => now()->addDays(37)->toDateString(),
        ]);

        $this->grantValidWorkout($user, $gym, now());

        $this->assertEquals(0, ChallengeParticipant::count());

        Carbon::setTestNow();
    }

    /** @test */
    public function no_challenge_does_not_create_participant()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        // Sem desafio criado
        $this->grantValidWorkout($user, $gym);

        $this->assertEquals(0, ChallengeParticipant::count());

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Admin — testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function admin_can_create_simple_challenge()
    {
        $gym  = Gym::factory()->create();
        $this->createAdminUser($gym);

        $response = $this->postJson('/api/admin/challenges', [
            'type'          => 'simple',
            'name'          => 'Desafio de Janeiro',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'goal_workouts' => 12,
            'reward_points' => 300,
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('challenge.type', 'simple');
        $response->assertJsonPath('challenge.goal_workouts', 12);
    }

    /** @test */
    public function admin_can_create_competitive_challenge()
    {
        $gym  = Gym::factory()->create();
        $this->createAdminUser($gym);

        $response = $this->postJson('/api/admin/challenges', [
            'type'                 => 'competitive',
            'name'                 => 'Liga Mensal',
            'starts_at'            => now()->toDateString(),
            'ends_at'              => now()->addDays(28)->toDateString(),
            'min_weekly_workouts'  => 2,
            'max_weekly_workouts'  => 5,
            'weekly_points_config' => ['1' => 100, '2' => 80, '3' => 60],
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('challenge.type', 'competitive');
        $response->assertJsonPath('challenge.min_weekly_workouts', 2);
    }

    /** @test */
    public function admin_cannot_create_overlapping_challenge()
    {
        $gym  = Gym::factory()->create();
        $this->createAdminUser($gym);

        $this->createSimpleChallenge($gym, [
            'starts_at' => now()->toDateString(),
            'ends_at'   => now()->addDays(30)->toDateString(),
        ]);

        $response = $this->postJson('/api/admin/challenges', [
            'type'          => 'simple',
            'name'          => 'Conflito',
            'starts_at'     => now()->addDays(10)->toDateString(),
            'ends_at'       => now()->addDays(40)->toDateString(),
            'goal_workouts' => 10,
            'reward_points' => 100,
        ]);

        $response->assertStatus(422);
        $this->assertStringContainsString('Já existe', $response->json('message'));
    }

    /** @test */
    public function admin_can_finish_challenge_early()
    {
        $gym       = Gym::factory()->create();
        $this->createAdminUser($gym);
        $challenge = $this->createSimpleChallenge($gym);

        $response = $this->postJson("/api/admin/challenges/{$challenge->id}/finish");

        $response->assertStatus(200);
        $this->assertEquals('finished', GymChallenge::find($challenge->id)->status);
    }

    /** @test */
    public function finished_challenge_is_not_returned_as_active()
    {
        [$gym, $user] = $this->createAuthUser();

        $challenge = $this->createSimpleChallenge($gym);
        $challenge->update(['status' => 'finished']);

        $response = $this->getJson('/api/challenges/active');

        $response->assertStatus(200);
        $response->assertJsonPath('challenge', null);
    }

    /** @test */
    public function competitive_challenge_api_returns_my_progress()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();
        $this->createCompetitiveChallenge($gym, ['max_weekly_workouts' => 5]);

        $this->grantValidWorkout($user, $gym, now());
        $this->grantValidWorkout($user, $gym, now()->addHours(2));

        $response = $this->getJson('/api/challenges/active');

        $response->assertStatus(200);
        $response->assertJsonPath('challenge.type', 'competitive');
        $response->assertJsonPath('challenge.my_workouts_this_week', 2);
        $response->assertJsonPath('challenge.my_total_points', 0);

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Reward type — testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function simple_challenge_physical_reward_does_not_grant_points()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $challenge = $this->createSimpleChallenge($gym, [
            'goal_workouts' => 1,
            'reward_type'   => 'physical',
            'reward_points' => 200,
        ]);

        $this->grantValidWorkout($user, $gym);

        $participant = ChallengeParticipant::where('challenge_id', $challenge->id)
            ->where('user_id', $user->id)
            ->first();

        $this->assertTrue($participant->goal_completed);
        $this->assertFalse($participant->reward_granted);

        $user->refresh();
        $this->assertEquals(0, $user->points_balance);

        Carbon::setTestNow();
    }

    /** @test */
    public function simple_challenge_none_reward_does_not_grant_points()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $challenge = $this->createSimpleChallenge($gym, [
            'goal_workouts' => 1,
            'reward_type'   => 'none',
            'reward_points' => null,
        ]);

        $this->grantValidWorkout($user, $gym);

        $participant = ChallengeParticipant::where('challenge_id', $challenge->id)
            ->where('user_id', $user->id)
            ->first();

        $this->assertTrue($participant->goal_completed);
        $this->assertFalse($participant->reward_granted);

        $user->refresh();
        $this->assertEquals(0, $user->points_balance);

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Tabela padrão de pontuação — testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function competitive_challenge_uses_default_scoring_table_when_config_is_null()
    {
        $lastMonday = Carbon::now()->startOfWeek(Carbon::MONDAY)->subWeek();
        Carbon::setTestNow($lastMonday->copy()->addDays(2));

        [$gym, $user1] = $this->createAuthUser();

        $challenge = GymChallenge::create([
            'gym_id'               => $gym->id,
            'type'                 => 'competitive',
            'name'                 => 'Default Table Challenge',
            'starts_at'            => $lastMonday->toDateString(),
            'ends_at'              => now()->addDays(28)->toDateString(),
            'status'               => 'active',
            'min_weekly_workouts'  => 1,
            'max_weekly_workouts'  => 7,
            'weekly_points_config' => null,
        ]);

        $user2 = User::factory()->create(['gym_id' => $gym->id, 'points_balance' => 0]);

        // user1: 5 treinos (1º lugar)
        for ($i = 0; $i < 5; $i++) {
            $this->grantValidWorkout($user1, $gym, now()->addHours($i));
        }

        // user2: 3 treinos (2º lugar)
        Sanctum::actingAs($user2);
        for ($i = 0; $i < 3; $i++) {
            $this->grantValidWorkout($user2, $gym, now()->addHours($i));
        }

        Carbon::setTestNow(Carbon::now()->startOfWeek(Carbon::MONDAY)->addWeek());
        app(ChallengeService::class)->finalizeCompletedWeeks($challenge);

        $weekStart = $lastMonday->toDateString();

        $r1 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('user_id', $user1->id)->where('week_start', $weekStart)->first();
        $r2 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('user_id', $user2->id)->where('week_start', $weekStart)->first();

        // Tabela padrão: 1º→10, 2º→8
        $this->assertEquals(10, $r1->points_awarded);
        $this->assertEquals(8, $r2->points_awarded);

        Carbon::setTestNow();
    }

    /** @test */
    public function competitive_challenge_positions_outside_default_table_receive_zero()
    {
        $lastMonday = Carbon::now()->startOfWeek(Carbon::MONDAY)->subWeek();
        Carbon::setTestNow($lastMonday->copy()->addDays(2));

        [$gym, $user1] = $this->createAuthUser();

        $challenge = GymChallenge::create([
            'gym_id'               => $gym->id,
            'type'                 => 'competitive',
            'name'                 => 'Zero Positions Challenge',
            'starts_at'            => $lastMonday->toDateString(),
            'ends_at'              => now()->addDays(28)->toDateString(),
            'status'               => 'active',
            'min_weekly_workouts'  => 1,
            'max_weekly_workouts'  => 7,
            'weekly_points_config' => null,
        ]);

        // 9 usuários — o 9º lugar fica fora da tabela padrão (que vai até a 8ª posição)
        $users = [$user1];
        for ($i = 0; $i < 8; $i++) {
            $users[] = User::factory()->create(['gym_id' => $gym->id, 'points_balance' => 0]);
        }

        // Treinos decrescentes: user[0]=9, user[1]=8, ..., user[8]=1 (9 posições distintas)
        foreach ($users as $idx => $u) {
            Sanctum::actingAs($u);
            $workouts = 9 - $idx;
            for ($w = 0; $w < $workouts; $w++) {
                $this->grantValidWorkout($u, $gym, now()->addHours($w));
            }
        }

        Carbon::setTestNow(Carbon::now()->startOfWeek(Carbon::MONDAY)->addWeek());
        app(ChallengeService::class)->finalizeCompletedWeeks($challenge);

        $weekStart = $lastMonday->toDateString();

        $r9 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('user_id', $users[8]->id)
            ->where('week_start', $weekStart)
            ->first();

        $this->assertEquals(9, $r9->position);
        $this->assertEquals(0, $r9->points_awarded);

        // Confirma que os 8 primeiros receberam pontos
        $r8 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('user_id', $users[7]->id)
            ->where('week_start', $weekStart)
            ->first();

        $this->assertEquals(8, $r8->position);
        $this->assertEquals(1, $r8->points_awarded); // 8º lugar → 1 ponto

        Carbon::setTestNow();
    }

    /** @test */
    public function competitive_challenge_custom_config_overrides_default_table()
    {
        $lastMonday = Carbon::now()->startOfWeek(Carbon::MONDAY)->subWeek();
        Carbon::setTestNow($lastMonday->copy()->addDays(2));

        [$gym, $user1] = $this->createAuthUser();

        $challenge = $this->createCompetitiveChallenge($gym, [
            'starts_at'            => $lastMonday->toDateString(),
            'min_weekly_workouts'  => 1,
            'weekly_points_config' => ['1' => 500, '2' => 300],
        ]);

        $user2 = User::factory()->create(['gym_id' => $gym->id, 'points_balance' => 0]);

        for ($i = 0; $i < 3; $i++) {
            $this->grantValidWorkout($user1, $gym, now()->addHours($i));
        }
        Sanctum::actingAs($user2);
        for ($i = 0; $i < 2; $i++) {
            $this->grantValidWorkout($user2, $gym, now()->addHours($i));
        }

        Carbon::setTestNow(Carbon::now()->startOfWeek(Carbon::MONDAY)->addWeek());
        app(ChallengeService::class)->finalizeCompletedWeeks($challenge);

        $r1 = ChallengeWeeklyRanking::where('challenge_id', $challenge->id)
            ->where('user_id', $user1->id)
            ->where('week_start', $lastMonday->toDateString())
            ->first();

        // Config personalizado deve prevalecer sobre a tabela padrão
        $this->assertEquals(500, $r1->points_awarded);

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /workout/finish → challenge_progress — testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function finish_endpoint_returns_null_challenge_progress_when_no_active_challenge()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        Checkin::firstOrCreate([
            'user_id'      => $user->id,
            'gym_id'       => $gym->id,
            'checkin_date' => now()->toDateString(),
        ]);

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(20),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');
        $response->assertJsonPath('challenge_progress', null);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_endpoint_returns_challenge_progress_for_simple_challenge()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $this->createSimpleChallenge($gym, ['goal_workouts' => 5]);

        Checkin::firstOrCreate([
            'user_id'      => $user->id,
            'gym_id'       => $gym->id,
            'checkin_date' => now()->toDateString(),
        ]);

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(20),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');
        $response->assertJsonPath('challenge_progress.type', 'simple');
        $response->assertJsonPath('challenge_progress.my_workouts', 1);
        $response->assertJsonPath('challenge_progress.goal_workouts', 5);
        $response->assertJsonPath('challenge_progress.goal_completed', false);
        $response->assertJsonPath('challenge_progress.simple_goal_just_completed', false);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_endpoint_sets_simple_goal_just_completed_on_final_workout()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $this->createSimpleChallenge($gym, ['goal_workouts' => 1, 'reward_points' => 100]);

        Checkin::firstOrCreate([
            'user_id'      => $user->id,
            'gym_id'       => $gym->id,
            'checkin_date' => now()->toDateString(),
        ]);

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(20),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('challenge_progress.simple_goal_just_completed', true);
        $response->assertJsonPath('challenge_progress.goal_completed', true);
        $response->assertJsonPath('challenge_progress.my_workouts', 1);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_endpoint_returns_challenge_progress_for_competitive_challenge()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $this->createCompetitiveChallenge($gym, ['max_weekly_workouts' => 5]);

        Checkin::firstOrCreate([
            'user_id'      => $user->id,
            'gym_id'       => $gym->id,
            'checkin_date' => now()->toDateString(),
        ]);

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(20),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');
        $response->assertJsonPath('challenge_progress.type', 'competitive');
        $response->assertJsonPath('challenge_progress.my_workouts_this_week', 1);
        $response->assertJsonPath('challenge_progress.my_total_points', 0);
        $response->assertJsonPath('challenge_progress.simple_goal_just_completed', false);

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Participação lazy — testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function lazy_participation_no_participant_record_before_first_workout()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $challenge = $this->createSimpleChallenge($gym);

        // Sem treinos: registro de participante NÃO deve existir
        $this->assertEquals(0, ChallengeParticipant::where('challenge_id', $challenge->id)->count());

        $this->grantValidWorkout($user, $gym);

        // Após o primeiro treino: registro criado automaticamente
        $this->assertEquals(1, ChallengeParticipant::where('challenge_id', $challenge->id)->count());

        Carbon::setTestNow();
    }

    /** @test */
    public function lazy_participation_multiple_users_only_creates_participants_who_trained()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user1] = $this->createAuthUser();

        $challenge = $this->createSimpleChallenge($gym);

        $user2 = User::factory()->create(['gym_id' => $gym->id]);
        $user3 = User::factory()->create(['gym_id' => $gym->id]);

        // Apenas user1 treina
        $this->grantValidWorkout($user1, $gym);

        $this->assertEquals(1, ChallengeParticipant::where('challenge_id', $challenge->id)->count());

        $this->assertDatabaseHas('challenge_participants', [
            'challenge_id' => $challenge->id,
            'user_id'      => $user1->id,
        ]);
        $this->assertDatabaseMissing('challenge_participants', [
            'challenge_id' => $challenge->id,
            'user_id'      => $user2->id,
        ]);
        $this->assertDatabaseMissing('challenge_participants', [
            'challenge_id' => $challenge->id,
            'user_id'      => $user3->id,
        ]);

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Acúmulo multi-semana — testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function competitive_total_points_accumulate_correctly_across_multiple_weeks()
    {
        $firstMonday = Carbon::now()->startOfWeek(Carbon::MONDAY)->subWeeks(2);

        // === Semana 1 ===
        Carbon::setTestNow($firstMonday->copy()->addDays(2));

        [$gym, $user1] = $this->createAuthUser();

        $challenge = $this->createCompetitiveChallenge($gym, [
            'starts_at'            => $firstMonday->toDateString(),
            'min_weekly_workouts'  => 1,
            'max_weekly_workouts'  => 7,
            'weekly_points_config' => ['1' => 10, '2' => 8],
        ]);

        $user2 = User::factory()->create(['gym_id' => $gym->id, 'points_balance' => 0]);

        // Semana 1: user1 → 1º (3 treinos), user2 → 2º (2 treinos)
        for ($i = 0; $i < 3; $i++) {
            $this->grantValidWorkout($user1, $gym, now()->addHours($i));
        }
        Sanctum::actingAs($user2);
        for ($i = 0; $i < 2; $i++) {
            $this->grantValidWorkout($user2, $gym, now()->addHours($i));
        }

        // === Semana 2 ===
        Carbon::setTestNow($firstMonday->copy()->addWeeks(1)->addDays(2));

        // Semana 2: user2 → 1º (5 treinos), user1 → 2º (2 treinos)  — posições invertidas
        Sanctum::actingAs($user2);
        for ($i = 0; $i < 5; $i++) {
            $this->grantValidWorkout($user2, $gym, now()->addHours($i));
        }
        Sanctum::actingAs($user1);
        for ($i = 0; $i < 2; $i++) {
            $this->grantValidWorkout($user1, $gym, now()->addHours($i));
        }

        // === Avança para semana 3: dispara finalização de ambas as semanas ===
        Carbon::setTestNow($firstMonday->copy()->addWeeks(2)->addDays(1));
        app(ChallengeService::class)->finalizeCompletedWeeks($challenge);

        $p1 = ChallengeParticipant::where('challenge_id', $challenge->id)
            ->where('user_id', $user1->id)->first();
        $p2 = ChallengeParticipant::where('challenge_id', $challenge->id)
            ->where('user_id', $user2->id)->first();

        // user1: semana1(10) + semana2(8) = 18
        // user2: semana1(8)  + semana2(10) = 18
        $this->assertEquals(18, $p1->total_challenge_points);
        $this->assertEquals(18, $p2->total_challenge_points);

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // my_position na API — testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function competitive_api_returns_null_position_when_user_has_no_activity()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $this->createCompetitiveChallenge($gym);

        $response = $this->getJson('/api/challenges/active');

        $response->assertStatus(200);
        $response->assertJsonPath('challenge.my_position', null);

        Carbon::setTestNow();
    }

    /** @test */
    public function competitive_api_returns_position_after_user_trains()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $this->createCompetitiveChallenge($gym, ['max_weekly_workouts' => 5]);

        $this->grantValidWorkout($user, $gym, now());

        $response = $this->getJson('/api/challenges/active');

        $response->assertStatus(200);

        $position = $response->json('challenge.my_position');
        $this->assertNotNull($position);
        $this->assertIsInt($position);
        $this->assertGreaterThanOrEqual(1, $position);

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Auto-atribuição
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function creating_challenge_assigns_participants_to_all_existing_students()
    {
        [$gym, $user1] = $this->createAuthUser();
        $user2 = User::factory()->create(['gym_id' => $gym->id, 'role' => 'user']);

        $admin = $this->createAdminUser($gym);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/admin/challenges', [
            'type'          => 'simple',
            'name'          => 'Desafio Geral',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'goal_workouts' => 5,
            'reward_points' => 100,
        ]);

        $response->assertStatus(201);
        $challengeId = $response->json('challenge.id');

        $this->assertDatabaseHas('challenge_participants', ['challenge_id' => $challengeId, 'user_id' => $user1->id]);
        $this->assertDatabaseHas('challenge_participants', ['challenge_id' => $challengeId, 'user_id' => $user2->id]);
        // Admin não deve ser atribuído
        $this->assertDatabaseMissing('challenge_participants', ['challenge_id' => $challengeId, 'user_id' => $admin->id]);
    }

    /** @test */
    public function new_student_is_assigned_to_active_challenge_on_register()
    {
        $gym = Gym::factory()->create();
        $this->createSimpleChallenge($gym, ['starts_at' => now()->toDateString()]);

        $response = $this->postJson('/api/register', [
            'name'     => 'Novo Aluno',
            'email'    => 'novo@gymup.com',
            'password' => 'secret123',
            'gym_id'   => $gym->id,
        ]);

        $response->assertStatus(200);
        $userId = $response->json('user.id');

        $this->assertDatabaseHas('challenge_participants', [
            'gym_id'  => $gym->id,
            'user_id' => $userId,
        ]);
    }

    /** @test */
    public function new_student_has_zero_progress_when_assigned()
    {
        $gym = Gym::factory()->create();
        $challenge = $this->createSimpleChallenge($gym, [
            'starts_at'     => now()->toDateString(),
            'goal_workouts' => 5,
        ]);

        $this->postJson('/api/register', [
            'name'     => 'Aluno Zero',
            'email'    => 'zero@gymup.com',
            'password' => 'secret123',
            'gym_id'   => $gym->id,
        ]);

        $participant = \App\Models\ChallengeParticipant::where('challenge_id', $challenge->id)->first();

        $this->assertNotNull($participant);
        $this->assertEquals(0, $participant->workouts_this_challenge);
        $this->assertFalse($participant->goal_completed);
        $this->assertFalse($participant->reward_granted);
    }

    /** @test */
    public function reward_is_granted_when_student_completes_challenge_goal()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $challenge = $this->createSimpleChallenge($gym, [
            'goal_workouts' => 2,
            'reward_points' => 150,
            'reward_type'   => 'points',
        ]);

        $this->grantValidWorkout($user, $gym, now());
        $this->grantValidWorkout($user, $gym, now()->addDays(1));

        $participant = \App\Models\ChallengeParticipant::where('challenge_id', $challenge->id)
            ->where('user_id', $user->id)
            ->first();

        $this->assertTrue($participant->goal_completed);
        $this->assertTrue($participant->reward_granted);
        $user->refresh();
        $this->assertEquals(150, $user->points_balance);

        Carbon::setTestNow();
    }

    /** @test */
    public function reward_is_not_duplicated_on_extra_workouts()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $this->createSimpleChallenge($gym, [
            'goal_workouts' => 1,
            'reward_points' => 100,
            'reward_type'   => 'points',
        ]);

        $this->grantValidWorkout($user, $gym, now());
        $this->grantValidWorkout($user, $gym, now()->addDays(1));
        $this->grantValidWorkout($user, $gym, now()->addDays(2));

        $user->refresh();
        $this->assertEquals(100, $user->points_balance);

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Desafios pessoais — múltiplos simultâneos
    // ──────────────────────────────────────────────────────────────────────────

    private function createPersonalChallenge(Gym $gym, array $attrs = []): GymChallenge
    {
        return GymChallenge::create(array_merge([
            'gym_id'        => $gym->id,
            'type'          => 'simple',
            'scope'         => 'personal',
            'name'          => 'Desafio Pessoal',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'status'        => 'active',
            'goal_workouts' => 5,
            'reward_points' => 100,
            'reward_type'   => 'points',
        ], $attrs));
    }

    /** @test */
    public function multiple_personal_challenges_can_be_active_simultaneously()
    {
        [$gym, $user] = $this->createAuthUser();
        $admin = $this->createAdminUser($gym);
        Sanctum::actingAs($admin);

        // Dois pessoais criados no mesmo período — não deve dar conflito
        $r1 = $this->postJson('/api/admin/challenges', [
            'type'          => 'simple',
            'scope'         => 'personal',
            'name'          => 'Pessoal 1',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'goal_workouts' => 3,
        ]);
        $r2 = $this->postJson('/api/admin/challenges', [
            'type'          => 'simple',
            'scope'         => 'personal',
            'name'          => 'Pessoal 2',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'goal_workouts' => 5,
        ]);

        $r1->assertStatus(201);
        $r2->assertStatus(201);
    }

    /** @test */
    public function personal_challenge_does_not_conflict_with_community_challenge()
    {
        [$gym, $user] = $this->createAuthUser();
        $admin = $this->createAdminUser($gym);
        Sanctum::actingAs($admin);

        $this->postJson('/api/admin/challenges', [
            'type'          => 'simple',
            'scope'         => 'community',
            'name'          => 'Comunitário',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'goal_workouts' => 10,
        ])->assertStatus(201);

        // Personal no mesmo período não deve gerar conflito
        $this->postJson('/api/admin/challenges', [
            'type'          => 'simple',
            'scope'         => 'personal',
            'name'          => 'Pessoal',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'goal_workouts' => 3,
        ])->assertStatus(201);
    }

    /** @test */
    public function creating_personal_challenge_assigns_all_students()
    {
        [$gym, $user1] = $this->createAuthUser();
        $user2 = User::factory()->create(['gym_id' => $gym->id, 'role' => 'user']);

        $admin = $this->createAdminUser($gym);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/admin/challenges', [
            'type'          => 'simple',
            'scope'         => 'personal',
            'name'          => 'Pessoal',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'goal_workouts' => 3,
        ]);

        $response->assertStatus(201);
        $id = $response->json('challenge.id');

        $this->assertDatabaseHas('challenge_participants', ['challenge_id' => $id, 'user_id' => $user1->id]);
        $this->assertDatabaseHas('challenge_participants', ['challenge_id' => $id, 'user_id' => $user2->id]);
    }

    /** @test */
    public function new_student_receives_all_active_personal_challenges_on_register()
    {
        $gym = Gym::factory()->create();
        $p1  = $this->createPersonalChallenge($gym, ['name' => 'P1']);
        $p2  = $this->createPersonalChallenge($gym, ['name' => 'P2']);

        $response = $this->postJson('/api/register', [
            'name'     => 'Novo',
            'email'    => 'novo2@gymup.com',
            'password' => 'secret123',
            'gym_id'   => $gym->id,
        ]);

        $response->assertStatus(200);
        $userId = $response->json('user.id');

        $this->assertDatabaseHas('challenge_participants', ['challenge_id' => $p1->id, 'user_id' => $userId]);
        $this->assertDatabaseHas('challenge_participants', ['challenge_id' => $p2->id, 'user_id' => $userId]);
    }

    /** @test */
    public function workout_updates_progress_in_all_active_personal_challenges()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $p1 = $this->createPersonalChallenge($gym, ['name' => 'P1', 'goal_workouts' => 3]);
        $p2 = $this->createPersonalChallenge($gym, ['name' => 'P2', 'goal_workouts' => 5]);

        $this->grantValidWorkout($user, $gym, now());

        $part1 = ChallengeParticipant::where('challenge_id', $p1->id)->where('user_id', $user->id)->first();
        $part2 = ChallengeParticipant::where('challenge_id', $p2->id)->where('user_id', $user->id)->first();

        $this->assertEquals(1, $part1->workouts_this_challenge);
        $this->assertEquals(1, $part2->workouts_this_challenge);

        Carbon::setTestNow();
    }

    /** @test */
    public function each_personal_challenge_grants_reward_independently()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        // P1: meta 1 treino / P2: meta 2 treinos
        $this->createPersonalChallenge($gym, ['name' => 'P1', 'goal_workouts' => 1, 'reward_points' => 50]);
        $this->createPersonalChallenge($gym, ['name' => 'P2', 'goal_workouts' => 2, 'reward_points' => 80]);

        $this->grantValidWorkout($user, $gym, now());

        $user->refresh();
        $this->assertEquals(50, $user->points_balance); // só P1 concluído

        $this->grantValidWorkout($user, $gym, now()->addDays(1));

        $user->refresh();
        $this->assertEquals(130, $user->points_balance); // P1 + P2

        Carbon::setTestNow();
    }

    /** @test */
    public function active_endpoint_returns_personal_challenges_separately()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();
        Sanctum::actingAs($user);

        $this->createPersonalChallenge($gym, ['name' => 'P1']);
        $this->createPersonalChallenge($gym, ['name' => 'P2']);

        $response = $this->getJson('/api/challenges/active');

        $response->assertStatus(200);
        $response->assertJsonStructure(['challenge', 'personal_challenges']);
        $response->assertJsonCount(2, 'personal_challenges');
        $response->assertJsonPath('challenge', null); // sem desafio comunitário

        Carbon::setTestNow();
    }

    /** @test */
    public function workout_finish_response_includes_personal_challenges_progress()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createAuthUser();

        $this->createPersonalChallenge($gym, ['name' => 'P1', 'goal_workouts' => 3]);

        Checkin::firstOrCreate([
            'user_id'      => $user->id,
            'gym_id'       => $gym->id,
            'checkin_date' => now()->toDateString(),
        ]);

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(20),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonStructure(['personal_challenges_progress']);
        $this->assertCount(1, $response->json('personal_challenges_progress'));

        Carbon::setTestNow();
    }
}
