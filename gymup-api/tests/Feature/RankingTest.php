<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\User;
use App\Models\PointTransaction;
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
            'role' => 'user',
        ]);

        $user2 = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'user',
        ]);

        // Ranking é calculado por SUM(point_transactions), não por points_balance
        PointTransaction::factory()->create([
            'user_id' => $user1->id,
            'gym_id'  => $gym->id,
            'type'    => 'earn',
            'points'  => 50,
        ]);

        PointTransaction::factory()->create([
            'user_id' => $user2->id,
            'gym_id'  => $gym->id,
            'type'    => 'earn',
            'points'  => 100,
        ]);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/ranking');

        $response->assertStatus(200);

        $data = $response->json();

        // Resposta usa 'user_id', não 'id'
        $this->assertEquals($user2->id, $data[0]['user_id']);
        $this->assertEquals($user1->id, $data[1]['user_id']);
    }

    public function test_ranking_is_isolated_by_gym()
    {
        $gym1 = Gym::factory()->create();
        $gym2 = Gym::factory()->create();

        $userGym1 = User::factory()->create([
            'gym_id' => $gym1->id,
            'role' => 'user',
            'points_balance' => 100,
        ]);

        User::factory()->create([
            'gym_id' => $gym2->id,
            'role' => 'user',
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

    public function test_ranking_does_not_count_redemption_refunds_as_activity_points()
    {
        $gym = Gym::factory()->create();

        $user1 = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'user',
        ]);

        $user2 = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'user',
        ]);

        PointTransaction::factory()->create([
            'user_id' => $user1->id,
            'gym_id' => $gym->id,
            'type' => 'earn',
            'category' => 'workout',
            'points' => 20,
        ]);

        PointTransaction::factory()->create([
            'user_id' => $user2->id,
            'gym_id' => $gym->id,
            'type' => 'earn',
            'category' => 'redemption',
            'points' => 100,
            'description' => 'Resgate recusado: Camiseta',
        ]);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/ranking');

        $response->assertStatus(200);
        $response->assertJsonPath('0.user_id', $user1->id);
        $response->assertJsonPath('0.points', 20);
        $response->assertJsonPath('1.user_id', $user2->id);
        $response->assertJsonPath('1.points', 0);
    }

    public function test_admin_ranking_does_not_count_redemption_refunds_as_activity_points()
    {
        $gym = Gym::factory()->create();

        $admin = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'super_admin',
        ]);

        $user1 = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'user',
            'points_balance' => 20,
        ]);

        $user2 = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'user',
            'points_balance' => 100,
        ]);

        PointTransaction::factory()->create([
            'user_id' => $user1->id,
            'gym_id' => $gym->id,
            'type' => 'earn',
            'category' => 'workout',
            'points' => 20,
        ]);

        PointTransaction::factory()->create([
            'user_id' => $user2->id,
            'gym_id' => $gym->id,
            'type' => 'earn',
            'category' => 'redemption',
            'points' => 100,
            'description' => 'Resgate recusado: Camiseta',
        ]);

        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/ranking');

        $response->assertStatus(200);
        $response->assertJsonPath('ranking.0.user_id', $user1->id);
        $response->assertJsonPath('ranking.0.period_points', 20);
        $response->assertJsonPath('ranking.1.user_id', $user2->id);
        $response->assertJsonPath('ranking.1.period_points', 0);
    }

    public function test_hidden_user_is_anonymous_in_app_and_admin_rankings()
    {
        $gym = Gym::factory()->create();

        $admin = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'super_admin',
        ]);

        $hiddenUser = User::factory()->create([
            'gym_id' => $gym->id,
            'role' => 'user',
            'name' => 'Nome Privado',
            'email' => 'privado@example.com',
            'avatar_url' => 'avatars/private.jpg',
            'ranking_visible' => false,
        ]);

        PointTransaction::factory()->create([
            'user_id' => $hiddenUser->id,
            'gym_id' => $gym->id,
            'type' => 'earn',
            'category' => 'workout',
            'points' => 20,
        ]);

        Sanctum::actingAs($hiddenUser);
        $this->getJson('/api/ranking')
            ->assertOk()
            ->assertJsonPath('0.user_id', $hiddenUser->id)
            ->assertJsonPath('0.name', 'Anônimo')
            ->assertJsonPath('0.avatar_url', null);

        Sanctum::actingAs($admin);
        $this->getJson('/api/admin/ranking')
            ->assertOk()
            ->assertJsonPath('ranking.0.user_id', $hiddenUser->id)
            ->assertJsonPath('ranking.0.name', 'Anônimo')
            ->assertJsonPath('ranking.0.email', null)
            ->assertJsonPath('ranking.0.avatar_url', null);
    }
}
