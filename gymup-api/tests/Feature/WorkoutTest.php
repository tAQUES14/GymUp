<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Gym;
use App\Models\Checkin;
use App\Models\WorkoutSession;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Carbon\Carbon;

class WorkoutTest extends TestCase
{
    use RefreshDatabase;

    private function createUserWithCheckin(): array
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id, 'points_balance' => 0]);
        Sanctum::actingAs($user);

        Checkin::factory()->create([
            'user_id'      => $user->id,
            'gym_id'       => $gym->id,
            'checkin_date' => now()->toDateString(),
        ]);

        return [$gym, $user];
    }

    /** @test */
    public function finish_valid_workout_grants_points()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(15),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');
        $response->assertJsonPath('points_generated', 10);
        $response->assertJsonPath('checkin_validated', true);

        $user->refresh();
        $this->assertEquals(10, $user->points_balance);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_without_checkin_is_invalid()
    {
        Carbon::setTestNow(Carbon::now());

        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id, 'points_balance' => 0]);
        Sanctum::actingAs($user);

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(15),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'INVALID');
        $response->assertJsonPath('points_generated', 0);
        $response->assertJsonPath('checkin_validated', false);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_below_min_duration_is_invalid()
    {
        // Force min_minutes to 10 for this test regardless of .env
        config(['workout.min_minutes' => 10]);

        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(5),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 100,
            'duration_seconds'   => 300, // 5 minutes, below 10 min minimum
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'INVALID');
        $response->assertJsonPath('points_generated', 0);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_below_70_percent_is_invalid()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(15),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 65,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'INVALID');
        $response->assertJsonPath('points_generated', 0);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_partial_70_74_asks_for_confirmation()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        $session = WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(15),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 72,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'PARTIAL_CONFIRM');

        $session->refresh();
        $this->assertNull($session->finished_at);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_partial_with_confirmation_grants_proportional_points()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        $session = WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(15),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 72,
            'duration_seconds'   => 900,
            'confirm_partial'    => true,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');
        $response->assertJsonPath('points_generated', 7);

        $user->refresh();
        $this->assertEquals(7, $user->points_balance);

        $session->refresh();
        $this->assertNotNull($session->finished_at);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_returns_full_response_structure()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(15),
            'progress'   => 0,
        ]);

        $response = $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'status',
            'message',
            'points_generated',
            'streak_current',
            'total_points',
            'checkin_validated',
            'session',
        ]);

        Carbon::setTestNow();
    }

    /** @test */
    public function finish_without_active_session_returns_404()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        $this->postJson('/api/workout/finish')
            ->assertStatus(404);
    }

    /** @test */
    public function start_creates_session()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        $this->postJson('/api/workout/start')
            ->assertStatus(201)
            ->assertJsonPath('is_existing', false);
    }

    /** @test */
    public function start_is_idempotent()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        $this->postJson('/api/workout/start')->assertStatus(201);
        $this->postJson('/api/workout/start')
            ->assertStatus(200)
            ->assertJsonPath('is_existing', true);
    }
}
