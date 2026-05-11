<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\GymChain;
use App\Models\User;
use App\Models\PointTransaction;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class NetworkRankingTest extends TestCase
{
    use RefreshDatabase;

    public function test_ranking_with_scope_gym_lists_only_own_gym_students(): void
    {
        $chain = GymChain::factory()->create();
        $gym1  = Gym::factory()->create(['chain_id' => $chain->id]);
        $gym2  = Gym::factory()->create(['chain_id' => $chain->id]);

        $user1 = User::factory()->create(['gym_id' => $gym1->id, 'role' => 'user']);
        $user2 = User::factory()->create(['gym_id' => $gym2->id, 'role' => 'user']);

        PointTransaction::factory()->create([
            'user_id' => $user2->id,
            'gym_id'  => $gym2->id,
            'type'    => 'earn',
            'points'  => 100,
        ]);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/ranking?scope=gym');

        $response->assertStatus(200);
        $data = $response->json();
        $ids  = array_column($data, 'user_id');

        $this->assertContains($user1->id, $ids, 'user1 deve aparecer no ranking da própria academia');
        $this->assertNotContains($user2->id, $ids, 'user2 de outra filial não deve aparecer com scope=gym');
    }

    public function test_ranking_with_scope_chain_lists_all_branches_students(): void
    {
        $chain = GymChain::factory()->create();
        $gym1  = Gym::factory()->create(['chain_id' => $chain->id]);
        $gym2  = Gym::factory()->create(['chain_id' => $chain->id]);

        $user1 = User::factory()->create(['gym_id' => $gym1->id, 'role' => 'user']);
        $user2 = User::factory()->create(['gym_id' => $gym2->id, 'role' => 'user']);

        PointTransaction::factory()->create([
            'user_id' => $user1->id,
            'gym_id'  => $gym1->id,
            'type'    => 'earn',
            'points'  => 50,
        ]);
        PointTransaction::factory()->create([
            'user_id' => $user2->id,
            'gym_id'  => $gym2->id,
            'type'    => 'earn',
            'points'  => 100,
        ]);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/ranking?scope=chain');

        $response->assertStatus(200);
        $data = $response->json();
        $ids  = array_column($data, 'user_id');

        $this->assertContains($user1->id, $ids, 'user1 deve aparecer no ranking da rede');
        $this->assertContains($user2->id, $ids, 'user2 de outra filial da mesma rede deve aparecer');
        // user2 tem mais pontos, deve aparecer primeiro
        $this->assertEquals($user2->id, $data[0]['user_id']);
    }

    public function test_ranking_with_scope_chain_includes_gym_name_in_response(): void
    {
        $chain = GymChain::factory()->create();
        $gym1  = Gym::factory()->create(['chain_id' => $chain->id, 'name' => 'Filial Centro']);
        $gym2  = Gym::factory()->create(['chain_id' => $chain->id, 'name' => 'Filial Norte']);

        $user1 = User::factory()->create(['gym_id' => $gym1->id, 'role' => 'user']);
        $user2 = User::factory()->create(['gym_id' => $gym2->id, 'role' => 'user']);

        PointTransaction::factory()->create([
            'user_id' => $user2->id,
            'gym_id'  => $gym2->id,
            'type'    => 'earn',
            'points'  => 100,
        ]);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/ranking?scope=chain');

        $response->assertStatus(200);
        $data = $response->json();

        foreach ($data as $item) {
            $this->assertArrayHasKey('gym_name', $item, 'scope=chain deve incluir gym_name em cada item');
        }

        $user2Item = collect($data)->firstWhere('user_id', $user2->id);
        $this->assertEquals('Filial Norte', $user2Item['gym_name']);

        $user1Item = collect($data)->firstWhere('user_id', $user1->id);
        $this->assertEquals('Filial Centro', $user1Item['gym_name']);
    }

    public function test_ranking_with_scope_chain_for_independent_gym_returns_400(): void
    {
        $gym  = Gym::factory()->create(['chain_id' => null]);
        $user = User::factory()->create(['gym_id' => $gym->id, 'role' => 'user']);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/ranking?scope=chain');

        $response->assertStatus(400);
        $response->assertJsonPath('message', 'Academia não pertence a uma rede');
    }

    public function test_progress_period_works_with_chain_scope(): void
    {
        $chain = GymChain::factory()->create();
        $gym1  = Gym::factory()->create(['chain_id' => $chain->id, 'name' => 'Filial Sul']);
        $gym2  = Gym::factory()->create(['chain_id' => $chain->id, 'name' => 'Filial Leste']);

        $user1 = User::factory()->create(['gym_id' => $gym1->id, 'role' => 'user']);
        $user2 = User::factory()->create(['gym_id' => $gym2->id, 'role' => 'user']);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/ranking?period=progress&scope=chain');

        $response->assertStatus(200);
        $data = $response->json();
        $ids  = array_column($data, 'user_id');

        $this->assertContains($user1->id, $ids, 'user1 deve aparecer no progress ranking da rede');
        $this->assertContains($user2->id, $ids, 'user2 da outra filial deve aparecer com scope=chain');

        foreach ($data as $item) {
            $this->assertArrayHasKey('gym_name', $item, 'period=progress + scope=chain deve incluir gym_name');
            $this->assertArrayHasKey('growth_pct', $item);
        }
    }
}
