<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Checkin;
use App\Models\Gym;
use App\Models\GymChain;
use App\Models\User;
use App\Models\UserWorkoutPlan;
use App\Models\WorkoutPlan;
use App\Models\WorkoutPlanDay;
use App\Models\WorkoutSession;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

class NetworkCheckinTest extends TestCase
{
    use RefreshDatabase;

    // ──────────────────────────────────────────────────────────────────────────
    // 1. Sem rede — QR de outra academia bloqueado
    // ──────────────────────────────────────────────────────────────────────────

    public function test_gym_without_chain_only_accepts_own_qr(): void
    {
        $gymA = Gym::factory()->create();
        $gymB = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gymA->id]);

        Sanctum::actingAs($user);

        $this->postJson('/api/checkin', ['qr_token' => $gymB->qr_token])
            ->assertStatus(403)
            ->assertJsonFragment(['message' => 'QR Code não pertence à sua academia.']);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 2. Mesma rede — check-in em filial irmã liberado
    // ──────────────────────────────────────────────────────────────────────────

    public function test_student_can_checkin_at_sibling_branch_in_same_chain(): void
    {
        $chain = GymChain::factory()->create();
        $gymA  = Gym::factory()->create(['chain_id' => $chain->id]);
        $gymB  = Gym::factory()->create(['chain_id' => $chain->id]);
        $user  = User::factory()->create(['gym_id' => $gymA->id]);

        Sanctum::actingAs($user);

        $this->postJson('/api/checkin', ['qr_token' => $gymB->qr_token])
            ->assertStatus(200);

        // Checkin gravado com a filial escaneada
        $this->assertDatabaseHas('checkins', [
            'user_id' => $user->id,
            'gym_id'  => $gymB->id,
        ]);

        // Session criada via API: gym_id = filial principal, checkin_gym_id = filial escaneada
        $this->postJson('/api/workout/start')->assertStatus(201);

        $this->assertDatabaseHas('workout_sessions', [
            'user_id'        => $user->id,
            'gym_id'         => $gymA->id,
            'checkin_gym_id' => $gymB->id,
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 3. Redes diferentes — bloqueado
    // ──────────────────────────────────────────────────────────────────────────

    public function test_student_cannot_checkin_at_branch_of_different_chain(): void
    {
        $chain1 = GymChain::factory()->create();
        $chain2 = GymChain::factory()->create();
        $gymA   = Gym::factory()->create(['chain_id' => $chain1->id]);
        $gymB   = Gym::factory()->create(['chain_id' => $chain2->id]);
        $user   = User::factory()->create(['gym_id' => $gymA->id]);

        Sanctum::actingAs($user);

        $this->postJson('/api/checkin', ['qr_token' => $gymB->qr_token])
            ->assertStatus(403)
            ->assertJsonFragment(['message' => 'QR Code não pertence à sua rede.']);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 4. Pontos creditados à filial principal mesmo treinando em filial B
    // ──────────────────────────────────────────────────────────────────────────

    public function test_points_earned_at_branch_credit_to_home_gym(): void
    {
        Carbon::setTestNow(Carbon::now());

        $chain = GymChain::factory()->create();
        $gymA  = Gym::factory()->create(['chain_id' => $chain->id]);
        $gymB  = Gym::factory()->create(['chain_id' => $chain->id]);
        $user  = User::factory()->create([
            'gym_id'         => $gymA->id,
            'points_balance' => 0,
        ]);

        Sanctum::actingAs($user);

        $this->postJson('/api/checkin', ['qr_token' => $gymB->qr_token])
            ->assertStatus(200);

        $this->postJson('/api/workout/start')->assertStatus(201);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('status', 'VALID')
            ->assertJsonPath('checkin_validated', true);

        $this->assertGreaterThan(0, $response->json('points_generated'));

        $user->refresh();
        $this->assertGreaterThan(0, $user->points_balance, 'Pontos devem ir para a conta do usuário');

        $session = WorkoutSession::where('user_id', $user->id)->latest()->first();
        $this->assertEquals($gymA->id, $session->gym_id,        'gym_id deve ser a filial principal');
        $this->assertEquals($gymB->id, $session->checkin_gym_id, 'checkin_gym_id deve ser a filial escaneada');

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 5. Streak incrementa ao treinar em qualquer filial da rede
    // ──────────────────────────────────────────────────────────────────────────

    public function test_streak_increments_when_training_at_any_branch(): void
    {
        Carbon::setTestNow(Carbon::now());

        $chain = GymChain::factory()->create();
        $gymA  = Gym::factory()->create(['chain_id' => $chain->id]);
        $gymB  = Gym::factory()->create(['chain_id' => $chain->id]);
        $user  = User::factory()->create([
            'gym_id'         => $gymA->id,
            'points_balance' => 0,
            'current_streak' => 0,
        ]);

        Sanctum::actingAs($user);

        // Plano com o dia de hoje como dia de treino
        $dow  = Carbon::now()->dayOfWeek;
        $plan = WorkoutPlan::create([
            'gym_id'     => $gymA->id,
            'name'       => 'Plano Teste',
            'created_by' => $user->id,
        ]);
        WorkoutPlanDay::create([
            'plan_id'     => $plan->id,
            'day_of_week' => $dow,
            'name'        => 'Treino Hoje',
            'rest_day'    => false,
        ]);
        UserWorkoutPlan::create([
            'user_id'    => $user->id,
            'plan_id'    => $plan->id,
            'gym_id'     => $gymA->id,
            'started_at' => now(),
        ]);

        // Check-in na filial B
        $this->postJson('/api/checkin', ['qr_token' => $gymB->qr_token])
            ->assertStatus(200);

        // Inicia e conclui treino
        $this->postJson('/api/workout/start')->assertStatus(201);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('status', 'VALID')
            ->assertJsonPath('streak_just_increased', true);

        $user->refresh();
        $this->assertEquals(1, $user->current_streak, 'Streak deve incrementar ao treinar em filial da rede');

        Carbon::setTestNow();
    }
}
