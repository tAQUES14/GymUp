<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class RankingTest extends TestCase
{
    use RefreshDatabase;

    public function test_ranking_returns_users_ordered_by_points()
    {
        $gym = Gym::factory()->create();

        $user1 = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
            'points_balance' => 50,
        ]);

        $user2 = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'student',
            'points_balance' => 100,
        ]);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/ranking');

        $response->assertStatus(200);

        $data = $response->json();

        $this->assertEquals($user2->id, $data[0]['id']);
        $this->assertEquals($user1->id, $data[1]['id']);
    }

    public function test_ranking_is_isolated_by_gym()
    {
        $gym1 = Gym::factory()->create();
        $gym2 = Gym::factory()->create();

        $userGym1 = User::factory()->create([
            'gym_id' => $gym1->id,
            'role' => 'student',
            'points_balance' => 100,
        ]);

        User::factory()->create([
            'gym_id' => $gym2->id,
            'role' => 'student',
            'points_balance' => 999,
        ]);

        Sanctum::actingAs($userGym1);

        $response = $this->getJson('/api/ranking');

        $response->assertStatus(200);

        $data = $response->json();

        foreach ($data as $item) {
            $this->assertEquals($gym1->id, $userGym1->gym_id);
        }
    }
}