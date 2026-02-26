<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\User;
use App\Models\PointTransaction;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class PointHistoryTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_view_own_point_history()
    {
        $gym = Gym::factory()->create();

        $user = User::factory()->create([
            'gym_id' => $gym->id,
            'points_balance' => 100,
        ]);

        PointTransaction::factory()->create([
            'user_id' => $user->id,
            'gym_id' => $gym->id,
            'type' => 'earn',
            'points' => 10,
            'description' => 'Check-in diário',
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/points/history');

        $response->assertStatus(200);

        $this->assertCount(1, $response->json('data'));
    }

    public function test_user_cannot_see_other_users_history()
    {
        $gym = Gym::factory()->create();

        $user1 = User::factory()->create(['gym_id' => $gym->id]);
        $user2 = User::factory()->create(['gym_id' => $gym->id]);

        PointTransaction::factory()->create([
            'user_id' => $user2->id,
            'gym_id' => $gym->id,
            'type' => 'earn',
            'points' => 50,
        ]);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/points/history');

        $response->assertStatus(200);

        $this->assertCount(0, $response->json('data'));
    }
}