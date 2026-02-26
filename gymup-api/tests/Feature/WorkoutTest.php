<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\User;
use App\Models\WorkoutSession;
use App\Models\PointTransaction;
use Carbon\Carbon;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class WorkoutTest extends TestCase
{
    use RefreshDatabase;

    // ──────────────────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────────────────

    private function createAuthUser(): array
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create([
            'gym_id'         => $gym->id,
            'points_balance' => 0,
        ]);
        Sanctum::actingAs($user);

        return [$gym, $user];
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow(); // always reset mocked time after each test
        parent::tearDown();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Auth guard
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function unauthenticated_user_cannot_access_workout_endpoints()
    {
        $this->postJson('/api/workout/start')->assertStatus(401);
        $this->postJson('/api/workout/progress', ['progress' => 50])->assertStatus(401);
        $this->postJson('/api/workout/finish')->assertStatus(401);
        $this->getJson('/api/workout/status')->assertStatus(401);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/workout/start
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function user_can_start_a_workout_session()
    {
        [$gym, $user] = $this->createAuthUser();

        $response = $this->postJson('/api/workout/start');

        $response->assertStatus(201)
            ->assertJsonStructure([
                'message',
                'session' => ['id', 'started_at', 'is_active', 'progress', 'points_granted'],
            ]);

        $this->assertDatabaseHas('workout_sessions', [
            'user_id'        => $user->id,
            'gym_id'         => $gym->id,
            'points_granted' => false,
            'finished_at'    => null,
        ]);
    }

    /** @test */
    public function cannot_start_two_simultaneous_sessions()
    {
        [$gym, $user] = $this->createAuthUser();

        // Session already active
        WorkoutSession::factory()->create([
            'user_id' => $user->id,
            'gym_id'  => $gym->id,
        ]);

        $response = $this->postJson('/api/workout/start');

        $response->assertStatus(409);
    }

    /** @test */
    public function can_start_new_session_after_finishing_previous()
    {
        [$gym, $user] = $this->createAuthUser();

        // Previous session is finished
        WorkoutSession::factory()->finished()->create([
            'user_id' => $user->id,
            'gym_id'  => $gym->id,
        ]);

        $response = $this->postJson('/api/workout/start');

        $response->assertStatus(201);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/workout/progress — time condition
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function cannot_earn_points_before_minimum_time()
    {
        [$gym, $user] = $this->createAuthUser();

        Carbon::setTestNow(Carbon::now());

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now(),
            'progress'   => 0,
        ]);

        // Advance only 30 seconds — far below any min_minutes threshold
        Carbon::setTestNow(Carbon::now()->addSeconds(30));

        $response = $this->postJson('/api/workout/progress', ['progress' => 100]);

        $response->assertStatus(200);
        $this->assertFalse($response->json('points_just_granted'));
        $this->assertDatabaseHas('workout_sessions', [
            'user_id'        => $user->id,
            'points_granted' => false,
        ]);
        $this->assertEquals(0, $user->fresh()->points_balance);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/workout/progress — progress condition
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function cannot_earn_points_below_70_percent_progress()
    {
        [$gym, $user] = $this->createAuthUser();

        $minMinutes = (int) config('workout.min_minutes', 10);

        Carbon::setTestNow(Carbon::now());

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now(),
            'progress'   => 0,
        ]);

        // Advance past the minimum time
        Carbon::setTestNow(Carbon::now()->addMinutes($minMinutes + 1));

        // Progress is 69 — one below the 70 threshold
        $response = $this->postJson('/api/workout/progress', ['progress' => 69]);

        $response->assertStatus(200);
        $this->assertFalse($response->json('points_just_granted'));
        $this->assertEquals(0, $user->fresh()->points_balance);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/workout/progress — both conditions met
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function earns_points_when_both_time_and_progress_conditions_are_met()
    {
        [$gym, $user] = $this->createAuthUser();

        $minMinutes = (int) config('workout.min_minutes', 10);

        Carbon::setTestNow(Carbon::now());

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now(),
            'progress'   => 0,
        ]);

        Carbon::setTestNow(Carbon::now()->addMinutes($minMinutes + 1));

        // Exactly at the 70% threshold
        $response = $this->postJson('/api/workout/progress', ['progress' => 70]);

        $response->assertStatus(200);
        $this->assertTrue($response->json('points_just_granted'));

        $this->assertDatabaseHas('workout_sessions', [
            'user_id'        => $user->id,
            'points_granted' => true,
        ]);

        $this->assertEquals(10, $user->fresh()->points_balance);

        $this->assertDatabaseHas('point_transactions', [
            'user_id'     => $user->id,
            'type'        => 'earn',
            'points'      => 10,
            'description' => 'Treino concluído',
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/workout/finish — points not duplicated
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function points_are_not_granted_twice_when_finish_is_called_after_progress()
    {
        [$gym, $user] = $this->createAuthUser();

        $minMinutes = (int) config('workout.min_minutes', 10);

        Carbon::setTestNow(Carbon::now());

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now(),
            'progress'   => 0,
        ]);

        Carbon::setTestNow(Carbon::now()->addMinutes($minMinutes + 1));

        // Points granted via progress update
        $this->postJson('/api/workout/progress', ['progress' => 80]);
        $this->assertEquals(10, $user->fresh()->points_balance);

        // Finish should NOT grant points again
        $response = $this->postJson('/api/workout/finish');

        $response->assertStatus(200);
        $this->assertFalse($response->json('points_just_granted'));
        $this->assertEquals(10, $user->fresh()->points_balance);
        $this->assertEquals(1, PointTransaction::where('user_id', $user->id)->count());
    }

    /** @test */
    public function points_are_granted_on_finish_if_conditions_met_and_not_yet_granted()
    {
        [$gym, $user] = $this->createAuthUser();

        $minMinutes = (int) config('workout.min_minutes', 10);

        Carbon::setTestNow(Carbon::now());

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now(),
            'progress'   => 0,
        ]);

        // Update progress while time is not yet sufficient
        $this->postJson('/api/workout/progress', ['progress' => 80]);
        $this->assertEquals(0, $user->fresh()->points_balance);

        // Now advance past minimum time
        Carbon::setTestNow(Carbon::now()->addMinutes($minMinutes + 1));

        // Finish — conditions are now met, points should be granted here
        $response = $this->postJson('/api/workout/finish');

        $response->assertStatus(200);
        $this->assertTrue($response->json('points_just_granted'));
        $this->assertEquals(10, $user->fresh()->points_balance);
    }

    /** @test */
    public function no_points_when_user_exits_before_conditions_are_met()
    {
        [$gym, $user] = $this->createAuthUser();

        Carbon::setTestNow(Carbon::now());

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now(),
            'progress'   => 50, // below 70
        ]);

        // Finish immediately — neither condition is met
        $response = $this->postJson('/api/workout/finish');

        $response->assertStatus(200);
        $this->assertFalse($response->json('points_just_granted'));
        $this->assertEquals(0, $user->fresh()->points_balance);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GET /api/workout/status
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function status_returns_null_when_no_session_exists()
    {
        $this->createAuthUser();

        $response = $this->getJson('/api/workout/status');

        $response->assertStatus(200)
            ->assertJson(['session' => null]);
    }

    /** @test */
    public function status_returns_the_active_session()
    {
        [$gym, $user] = $this->createAuthUser();

        WorkoutSession::factory()->create([
            'user_id' => $user->id,
            'gym_id'  => $gym->id,
        ]);

        $response = $this->getJson('/api/workout/status');

        $response->assertStatus(200)
            ->assertJsonPath('session.is_active', true);
    }

    /** @test */
    public function status_returns_finished_session_as_inactive()
    {
        [$gym, $user] = $this->createAuthUser();

        WorkoutSession::factory()->finished()->create([
            'user_id' => $user->id,
            'gym_id'  => $gym->id,
        ]);

        $response = $this->getJson('/api/workout/status');

        $response->assertStatus(200)
            ->assertJsonPath('session.is_active', false);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Validation
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function progress_endpoint_requires_valid_integer_between_0_and_100()
    {
        $this->createAuthUser();

        $this->postJson('/api/workout/progress', ['progress' => 101])->assertStatus(422);
        $this->postJson('/api/workout/progress', ['progress' => -1])->assertStatus(422);
        $this->postJson('/api/workout/progress', [])->assertStatus(422);
    }
}
