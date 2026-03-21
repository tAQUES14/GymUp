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

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function unauthenticated_user_cannot_access_dashboard()
    {
        $this->getJson('/api/dashboard')
            ->assertStatus(401);
    }

    /** @test */
    public function authenticated_user_receives_dashboard_structure()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create([
            'gym_id'         => $gym->id,
            'role'           => 'student',
            'points_balance' => 100,
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'points_balance',
            'has_completed_today',
            'has_active_session',
            'has_checked_in_today',
            'weekly_progress',
            'recent_activities',
            'streak',
            'total_checkins',
            'total_workouts',
            'total_workouts_with_points',
        ]);
    }

    /** @test */
    public function has_checked_in_today_is_false_when_no_checkin_exists()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id, 'role' => 'student']);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');
        $response->assertStatus(200);
        $this->assertFalse($response->json('has_checked_in_today'));
    }

    /** @test */
    public function has_checked_in_today_is_true_when_checkin_exists_today()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id, 'role' => 'student']);

        // Create a checkin record (not a WorkoutSession)
        Checkin::factory()->create([
            'user_id'      => $user->id,
            'gym_id'       => $gym->id,
            'checkin_date' => Carbon::today()->toDateString(),
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');
        $response->assertStatus(200);
        $this->assertTrue($response->json('has_checked_in_today'));
    }

    /** @test */
    public function streak_counts_consecutive_days_with_checkin_and_valid_workout()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create([
            'gym_id'         => $gym->id,
            'role'           => 'student',
            'current_streak' => 3, // Streak is set directly (by StreakService on workout finish)
            'best_streak'    => 3,
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');
        $response->assertStatus(200);
        $this->assertEquals(3, $response->json('streak'));
        $this->assertEquals(3, $response->json('best_streak'));
    }

    /** @test */
    public function streak_is_zero_when_only_checkins_without_workouts()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id, 'role' => 'student']);

        // Only checkins, no valid workouts
        Checkin::factory()->create([
            'gym_id'       => $gym->id,
            'user_id'      => $user->id,
            'checkin_date' => Carbon::today(),
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');
        $response->assertStatus(200);
        $this->assertEquals(0, $response->json('streak'));
    }

    /** @test */
    public function streak_stops_when_sequence_is_broken()
    {
        $gym  = Gym::factory()->create();
        // Simulate a broken streak: user missed a training day, streak was reset to 0
        $user = User::factory()->create([
            'gym_id'         => $gym->id,
            'role'           => 'student',
            'current_streak' => 0,  // Broken
            'best_streak'    => 5,  // Previous best preserved
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');
        $response->assertStatus(200);
        $this->assertEquals(0, $response->json('streak'));
        $this->assertEquals(5, $response->json('best_streak'));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // total_workouts / total_workouts_with_points
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function total_workouts_counts_all_finished_sessions_including_without_points()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        // 2 treinos com pontos (criados separadamente para respeitar o partial unique index)
        WorkoutSession::factory()->finished()->withPointsGranted()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subHours(4),
        ]);
        WorkoutSession::factory()->finished()->withPointsGranted()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subHours(2),
        ]);

        // 1 treino sem pontos (bônus/inválido)
        WorkoutSession::factory()->finished()->create([
            'user_id'        => $user->id,
            'gym_id'         => $gym->id,
            'points_granted' => false,
        ]);

        $response = $this->getJson('/api/dashboard')->assertStatus(200);

        $this->assertEquals(3, $response->json('total_workouts'));
        $this->assertEquals(2, $response->json('total_workouts_with_points'));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // has_completed_today
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function has_completed_today_is_true_when_workout_with_points_granted_today()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        Carbon::setTestNow(Carbon::now());

        WorkoutSession::factory()->finished()->withPointsGranted()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now(),
        ]);

        $this->getJson('/api/dashboard')
            ->assertStatus(200)
            ->assertJsonPath('has_completed_today', true);

        Carbon::setTestNow();
    }

    /** @test */
    public function has_completed_today_is_false_when_no_points_granted_today()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        WorkoutSession::factory()->finished()->create([
            'user_id' => $user->id,
            'gym_id'  => $gym->id,
        ]);

        $this->getJson('/api/dashboard')
            ->assertStatus(200)
            ->assertJsonPath('has_completed_today', false);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // has_active_session
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function has_active_session_is_true_when_unfinished_session_exists()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        WorkoutSession::factory()->create([
            'user_id' => $user->id,
            'gym_id'  => $gym->id,
        ]);

        $this->getJson('/api/dashboard')
            ->assertStatus(200)
            ->assertJsonPath('has_active_session', true);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // weekly_progress
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function weekly_progress_marks_correct_days()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        Carbon::setTestNow(Carbon::parse('2025-01-08 12:00:00'));

        WorkoutSession::factory()->create([
            'user_id'     => $user->id,
            'gym_id'      => $gym->id,
            'started_at'  => Carbon::parse('2025-01-06 10:00:00'),
            'finished_at' => Carbon::parse('2025-01-06 10:30:00'),
        ]);

        $response = $this->getJson('/api/dashboard')->assertStatus(200);

        $weekly = $response->json('weekly_progress');

        $this->assertCount(7, $weekly);
        $this->assertTrue($weekly[0]);  // Monday — trained
        $this->assertFalse($weekly[1]); // Tuesday
        $this->assertFalse($weekly[2]); // Wednesday
        $this->assertFalse($weekly[6]); // Sunday

        Carbon::setTestNow();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // recent_activities
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function recent_activities_returns_at_most_5_items()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        for ($i = 1; $i <= 6; $i++) {
            WorkoutSession::factory()->create([
                'user_id'     => $user->id,
                'gym_id'      => $gym->id,
                'started_at'  => now()->subDays($i),
                'finished_at' => now()->subDays($i)->addMinutes(30),
            ]);
        }

        $this->getJson('/api/dashboard')
            ->assertStatus(200)
            ->assertJsonCount(5, 'recent_activities');
    }
}
