<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Gym;
use App\Models\Checkin;
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
            'has_checked_in_today',
            'streak',
            'total_checkins'
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
}