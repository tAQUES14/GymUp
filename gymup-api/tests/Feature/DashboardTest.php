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
        $gym = Gym::factory()->create();

        $user = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
            'points_balance' => 100
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
        ]);
    }

    /** @test */
    public function has_checked_in_today_is_false_when_no_checkin_exists()
    {
        $gym = Gym::factory()->create();

        $user = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');

        $response->assertStatus(200);
        $this->assertFalse($response->json('has_checked_in_today'));
    }

    /** @test */
    public function has_checked_in_today_is_true_when_checkin_exists_today()
    {
        $gym = Gym::factory()->create();

        $user = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
        ]);

        Checkin::factory()->create([
            'gym_id' => $gym->id,
            'user_id' => $user->id,
            'checkin_date' => Carbon::today()
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');

        $response->assertStatus(200);
        $this->assertTrue($response->json('has_checked_in_today'));
    }

    /** @test */
    public function streak_counts_consecutive_days_correctly()
    {
        $gym = Gym::factory()->create();

        $user = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
        ]);

        // 3 dias consecutivos (hoje, ontem, anteontem)
        Checkin::factory()->create([
            'gym_id' => $gym->id,
            'user_id' => $user->id,
            'checkin_date' => Carbon::today()
        ]);

        Checkin::factory()->create([
            'gym_id' => $gym->id,
            'user_id' => $user->id,
            'checkin_date' => Carbon::yesterday()
        ]);

        Checkin::factory()->create([
            'gym_id' => $gym->id,
            'user_id' => $user->id,
            'checkin_date' => Carbon::today()->subDays(2)
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');

        $response->assertStatus(200);
        $this->assertEquals(3, $response->json('streak'));
    }

    /** @test */
    public function streak_stops_when_sequence_is_broken()
    {
        $gym = Gym::factory()->create();

        $user = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
        ]);

        // hoje
        Checkin::factory()->create([
            'gym_id' => $gym->id,
            'user_id' => $user->id,
            'checkin_date' => Carbon::today()
        ]);

        // anteontem (quebra ontem)
        Checkin::factory()->create([
            'gym_id' => $gym->id,
            'user_id' => $user->id,
            'checkin_date' => Carbon::today()->subDays(2)
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/dashboard');

        $response->assertStatus(200);

        // streak deve ser 1 (apenas hoje)
        $this->assertEquals(1, $response->json('streak'));
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

        // Fix "now" to a Wednesday (2025-01-08)
        Carbon::setTestNow(Carbon::parse('2025-01-08 12:00:00'));

        // Finished session on Monday of this week (2025-01-06)
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
        $this->assertFalse($weekly[1]); // Tuesday — not trained
        $this->assertFalse($weekly[2]); // Wednesday — not trained
        $this->assertFalse($weekly[6]); // Sunday — not trained

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