<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\User;
use App\Models\Redemption;
use App\Models\PointTransaction;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class AdminDashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_dashboard_returns_correct_metrics()
    {
        $gym = Gym::factory()->create();

        $admin = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'admin'
        ]);

        $student = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
            'points_balance' => 50
        ]);

        PointTransaction::factory()->create([
            'gym_id' => $gym->id,
            'user_id' => $student->id,
            'type' => 'earn',
            'points' => 30
        ]);

        Redemption::factory()->create([
            'gym_id' => $gym->id,
            'user_id' => $student->id,
            'status' => 'pending'
        ]);

        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/dashboard');

        $response->assertStatus(200);

        $response->assertJsonStructure([
            'total_students',
            'total_points_distributed',
            'pending_redemptions',
            'approved_redemptions',
            'top_students'
        ]);
    }

    public function test_student_cannot_access_admin_dashboard()
    {
        $gym = Gym::factory()->create();

        $student = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student'
        ]);

        Sanctum::actingAs($student);

        $this->getJson('/api/admin/dashboard')
            ->assertStatus(403);
    }
}