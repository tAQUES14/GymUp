<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Gym;
use App\Models\Reward;
use App\Models\Redemption;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class RedemptionApprovalTest extends TestCase
{
    use RefreshDatabase;

    public function test_student_cannot_approve_redemption()
    {
        $gym = Gym::factory()->create();

        $student = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
            'points_balance' => 100
        ]);

        $reward = Reward::factory()->create([
            'gym_id' => $gym->id,
            'points_cost' => 20,
            'stock' => 10
        ]);

        $redemption = Redemption::factory()->create([
            'user_id' => $student->id,
            'reward_id' => $reward->id,
            'gym_id' => $gym->id,
            'points_spent' => 20,
            'status' => 'pending'
        ]);

        Sanctum::actingAs($student);

        $response = $this->postJson("/api/redemptions/{$redemption->id}/approve");

        $response->assertStatus(403);
    }

    public function test_admin_can_approve_redemption()
    {
        $gym = Gym::factory()->create();

        $admin = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'admin',
            'points_balance' => 100
        ]);

        $reward = Reward::factory()->create([
            'gym_id' => $gym->id,
            'points_cost' => 20,
            'stock' => 10
        ]);

        $redemption = Redemption::factory()->create([
            'user_id' => $admin->id,
            'reward_id' => $reward->id,
            'gym_id' => $gym->id,
            'points_spent' => 20,
            'status' => 'pending'
        ]);

        Sanctum::actingAs($admin);

        $response = $this->postJson("/api/redemptions/{$redemption->id}/approve");

        $response->assertStatus(200);

        $this->assertDatabaseHas('redemptions', [
            'id' => $redemption->id,
            'status' => 'approved'
        ]);
    }

    public function test_approval_decreases_user_balance_and_stock()
    {
        $gym = Gym::factory()->create();

        $admin = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'admin',
            'points_balance' => 100
        ]);

        $reward = Reward::factory()->create([
            'gym_id' => $gym->id,
            'points_cost' => 20,
            'stock' => 10
        ]);

        $redemption = Redemption::factory()->create([
            'user_id' => $admin->id,
            'reward_id' => $reward->id,
            'gym_id' => $gym->id,
            'points_spent' => 20,
            'status' => 'pending'
        ]);

        Sanctum::actingAs($admin);

        $this->postJson("/api/redemptions/{$redemption->id}/approve");

        $this->assertDatabaseHas('users', [
            'id' => $admin->id,
            'points_balance' => 80
        ]);

        $this->assertDatabaseHas('rewards', [
            'id' => $reward->id,
            'stock' => 9
        ]);
    }

    public function test_admin_cannot_approve_redemption_from_another_gym()
{
    $gym1 = \App\Models\Gym::factory()->create();
    $gym2 = \App\Models\Gym::factory()->create();

    $adminGym1 = \App\Models\User::factory()->create([
        'gym_id' => $gym1->id,
        'role' => 'admin',
        'points_balance' => 100
    ]);

    $rewardGym2 = \App\Models\Reward::factory()->create([
        'gym_id' => $gym2->id,
        'points_cost' => 20,
        'stock' => 10
    ]);

    $redemptionGym2 = \App\Models\Redemption::factory()->create([
        'user_id' => \App\Models\User::factory()->create([
            'gym_id' => $gym2->id,
            'points_balance' => 100
        ])->id,
        'reward_id' => $rewardGym2->id,
        'gym_id' => $gym2->id,
        'points_spent' => 20,
        'status' => 'pending'
    ]);

    \Laravel\Sanctum\Sanctum::actingAs($adminGym1);

    $response = $this->postJson("/api/redemptions/{$redemptionGym2->id}/approve");

    $response->assertStatus(403);
}
}