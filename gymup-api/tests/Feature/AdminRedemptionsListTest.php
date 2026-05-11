<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\User;
use App\Models\Reward;
use App\Models\Redemption;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class AdminRedemptionsListTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_list_only_own_gym_redemptions()
    {
        $gym1 = Gym::factory()->create();
        $gym2 = Gym::factory()->create();

        $admin = User::factory()->create([
            'gym_id' => $gym1->id,
            'role' => 'super_admin',
            'points_balance' => 100,
        ]);

        $reward1 = Reward::factory()->create(['gym_id' => $gym1->id]);
        $reward2 = Reward::factory()->create(['gym_id' => $gym2->id]);

        $r1 = Redemption::factory()->create([
            'gym_id' => $gym1->id,
            'reward_id' => $reward1->id,
            'user_id' => User::factory()->create(['gym_id' => $gym1->id])->id,
            'status' => 'pending',
        ]);

        Redemption::factory()->create([
            'gym_id' => $gym2->id,
            'reward_id' => $reward2->id,
            'user_id' => User::factory()->create(['gym_id' => $gym2->id])->id,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/redemptions');

        $response->assertStatus(200);

        // garante que retornou o da gym1
        $response->assertJsonFragment(['id' => $r1->id]);

        // e garante que só tem items da gym1
        $data = $response->json('data');
        foreach ($data as $item) {
            $this->assertEquals($gym1->id, $item['gym_id']);
        }
    }

    public function test_student_cannot_list_admin_redemptions()
    {
        $gym = Gym::factory()->create();

        $student = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
        ]);

        Sanctum::actingAs($student);

        $this->getJson('/api/admin/redemptions')
            ->assertStatus(403);
    }
}