<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Checkin;
use App\Models\Gym;
use App\Models\GymChain;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class NetworkAdminTest extends TestCase
{
    use RefreshDatabase;

    private function makeNetworkAdmin(GymChain $chain): User
    {
        $gym   = Gym::factory()->create(['chain_id' => $chain->id]);
        $admin = User::factory()->create(['role' => 'network_admin', 'gym_id' => $gym->id]);
        Sanctum::actingAs($admin);
        return $admin;
    }

    private function makeTrainer(Gym $gym): User
    {
        $trainer = User::factory()->create(['role' => 'trainer', 'gym_id' => $gym->id]);
        $trainer->gyms()->attach($gym->id, ['is_primary' => true, 'created_at' => now()]);
        return $trainer;
    }

    // ── 1. Dashboard filtrado pela própria rede ───────────────────────────────

    public function test_network_admin_sees_only_own_network_dashboard(): void
    {
        $chain    = GymChain::factory()->create();
        $gym1     = Gym::factory()->create(['chain_id' => $chain->id]);
        $this->makeNetworkAdmin($chain);

        $student1 = User::factory()->create(['gym_id' => $gym1->id, 'role' => 'user']);

        // Student from a different, independent gym — should NOT appear in counts
        $otherGym = Gym::factory()->create(['chain_id' => null]);
        User::factory()->create(['gym_id' => $otherGym->id, 'role' => 'user']);

        Checkin::factory()->create(['gym_id' => $gym1->id, 'user_id' => $student1->id, 'checkin_date' => today()]);

        $response = $this->getJson('/api/network/dashboard');
        $response->assertStatus(200);

        // total_students conta apenas alunos da rede
        // A rede tem 2 gyms (gym1 + o gym do network_admin), student1 está em gym1
        $this->assertEquals(1, $response->json('total_students'));
        $this->assertEquals(1, $response->json('weekly_checkins'));
    }

    // ── 2. Criar filial na própria rede ──────────────────────────────────────

    public function test_network_admin_can_create_gym_in_own_network(): void
    {
        $chain = GymChain::factory()->create();
        $this->makeNetworkAdmin($chain);

        $response = $this->postJson('/api/network/gyms', [
            'name'    => 'Nova Filial Centro',
            'address' => 'Rua das Flores, 100',
            'city'    => 'São Paulo',
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('gym.name', 'Nova Filial Centro');
        $response->assertJsonPath('gym.city', 'São Paulo');

        $this->assertDatabaseHas('gyms', ['name' => 'Nova Filial Centro', 'chain_id' => $chain->id]);
    }

    // ── 3. Não pode gerenciar filial de outra rede ───────────────────────────

    public function test_network_admin_cannot_create_gym_in_other_network(): void
    {
        $chain1 = GymChain::factory()->create();
        $chain2 = GymChain::factory()->create();
        $this->makeNetworkAdmin($chain1);

        $foreignGym = Gym::factory()->create(['chain_id' => $chain2->id]);

        // Trying to update a gym from chain2 must return 403
        $response = $this->putJson("/api/network/gyms/{$foreignGym->id}", [
            'name' => 'Hackeado',
        ]);

        $response->assertStatus(403);
        $this->assertDatabaseMissing('gyms', ['id' => $foreignGym->id, 'name' => 'Hackeado']);
    }

    // ── 4. Vincular trainer a filial da rede ─────────────────────────────────

    public function test_network_admin_can_link_trainer_to_own_gym(): void
    {
        $chain   = GymChain::factory()->create();
        $gym     = Gym::factory()->create(['chain_id' => $chain->id]);
        $this->makeNetworkAdmin($chain);

        // Trainer not yet linked to gym
        $trainer = User::factory()->create(['role' => 'trainer', 'gym_id' => $gym->id]);

        $response = $this->postJson("/api/network/trainers/{$trainer->id}/gyms", [
            'gym_id' => $gym->id,
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('trainer_gyms', ['trainer_id' => $trainer->id, 'gym_id' => $gym->id]);
    }

    // ── 5. Não pode desvincular a única filial do trainer ────────────────────

    public function test_network_admin_cannot_unlink_trainer_last_gym(): void
    {
        $chain   = GymChain::factory()->create();
        $gym     = Gym::factory()->create(['chain_id' => $chain->id]);
        $this->makeNetworkAdmin($chain);

        $trainer = $this->makeTrainer($gym);

        $this->assertEquals(1, $trainer->gyms()->count(), 'Trainer deve ter exatamente 1 filial');

        $response = $this->deleteJson("/api/network/trainers/{$trainer->id}/gyms/{$gym->id}");

        $response->assertStatus(422);
        $this->assertDatabaseHas('trainer_gyms', ['trainer_id' => $trainer->id, 'gym_id' => $gym->id]);
    }

    // ── 6. Não pode acessar dados de outra rede ──────────────────────────────

    public function test_network_admin_cannot_access_other_network_data(): void
    {
        $chain1 = GymChain::factory()->create();
        $chain2 = GymChain::factory()->create();
        $gym2   = Gym::factory()->create(['chain_id' => $chain2->id]);
        $this->makeNetworkAdmin($chain1);

        // GET /api/network/gyms should NOT include gym2 from chain2
        $response = $this->getJson('/api/network/gyms');
        $response->assertStatus(200);
        $ids = array_column($response->json('gyms'), 'id');
        $this->assertNotContains($gym2->id, $ids);

        // PUT on gym2 must be 403
        $this->putJson("/api/network/gyms/{$gym2->id}", ['name' => 'X'])->assertStatus(403);
    }

    // ── 7. Roles não autorizados recebem 403 ─────────────────────────────────

    public function test_non_network_admin_cannot_access_network_endpoints(): void
    {
        $gym   = Gym::factory()->create();
        $admin = User::factory()->create(['gym_id' => $gym->id, 'role' => 'gym_admin']);
        Sanctum::actingAs($admin);

        $this->getJson('/api/network/dashboard')->assertStatus(403);
        $this->getJson('/api/network/gyms')->assertStatus(403);
        $this->postJson('/api/network/gyms', ['name' => 'X'])->assertStatus(403);
    }
}
