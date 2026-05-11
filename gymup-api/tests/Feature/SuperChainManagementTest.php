<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\GymChain;
use App\Models\User;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class SuperChainManagementTest extends TestCase
{
    use RefreshDatabase;

    private function superAdmin(): User
    {
        $user = User::factory()->create(['role' => 'super_admin', 'gym_id' => null]);
        Sanctum::actingAs($user);
        return $user;
    }

    // ── LIST ─────────────────────────────────────────────────────────────────

    public function test_super_admin_can_list_chains_with_gym_count(): void
    {
        $this->superAdmin();

        $chain1 = GymChain::factory()->create(['name' => 'Rede Alpha']);
        $chain2 = GymChain::factory()->create(['name' => 'Rede Beta']);

        Gym::factory()->create(['chain_id' => $chain1->id]);
        Gym::factory()->create(['chain_id' => $chain1->id]);
        Gym::factory()->create(['chain_id' => $chain2->id]);

        $response = $this->getJson('/api/super/chains');
        $response->assertStatus(200);

        $data = $response->json('data');
        $this->assertCount(2, $data);

        $alpha = collect($data)->firstWhere('id', $chain1->id);
        $this->assertEquals(2, $alpha['gyms_count']);

        $beta = collect($data)->firstWhere('id', $chain2->id);
        $this->assertEquals(1, $beta['gyms_count']);
    }

    // ── STORE ─────────────────────────────────────────────────────────────────

    public function test_super_admin_can_create_chain_with_auto_slug(): void
    {
        $this->superAdmin();

        $response = $this->postJson('/api/super/chains', [
            'name' => 'Smart Fit Brasil',
        ]);

        $response->assertStatus(201);
        $response->assertJsonPath('chain.name', 'Smart Fit Brasil');

        $slug = $response->json('chain.slug');
        $this->assertStringStartsWith('smart-fit-brasil', $slug);

        $this->assertDatabaseHas('gym_chains', ['name' => 'Smart Fit Brasil', 'slug' => $slug]);
    }

    public function test_super_admin_cannot_create_chain_with_duplicate_slug(): void
    {
        $this->superAdmin();

        GymChain::factory()->create(['slug' => 'my-chain']);

        $response = $this->postJson('/api/super/chains', [
            'name' => 'Another Chain',
            'slug' => 'my-chain',
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrorFor('slug');
    }

    // ── UPDATE ────────────────────────────────────────────────────────────────

    public function test_super_admin_can_update_chain(): void
    {
        $this->superAdmin();
        $chain = GymChain::factory()->create(['name' => 'Old Name', 'slug' => 'old-name']);

        $response = $this->putJson("/api/super/chains/{$chain->id}", [
            'name' => 'New Name',
            'slug' => 'new-name',
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('chain.name', 'New Name');
        $response->assertJsonPath('chain.slug', 'new-name');

        $this->assertDatabaseHas('gym_chains', ['id' => $chain->id, 'name' => 'New Name', 'slug' => 'new-name']);
    }

    // ── DESTROY ───────────────────────────────────────────────────────────────

    public function test_super_admin_can_delete_chain_and_gyms_become_independent(): void
    {
        $this->superAdmin();
        $chain = GymChain::factory()->create();
        $gym1  = Gym::factory()->create(['chain_id' => $chain->id]);
        $gym2  = Gym::factory()->create(['chain_id' => $chain->id]);

        $response = $this->deleteJson("/api/super/chains/{$chain->id}");
        $response->assertStatus(200);

        $this->assertDatabaseMissing('gym_chains', ['id' => $chain->id]);
        $this->assertNull($gym1->fresh()->chain_id, 'gym1 deve ficar independente');
        $this->assertNull($gym2->fresh()->chain_id, 'gym2 deve ficar independente');
    }

    // ── LINK ──────────────────────────────────────────────────────────────────

    public function test_super_admin_can_link_independent_gym_to_chain(): void
    {
        $this->superAdmin();
        $chain = GymChain::factory()->create();
        $gym   = Gym::factory()->create(['chain_id' => null]);

        $response = $this->postJson("/api/super/chains/{$chain->id}/gyms", ['gym_id' => $gym->id]);
        $response->assertStatus(200);

        $this->assertEquals($chain->id, $gym->fresh()->chain_id);
    }

    public function test_super_admin_cannot_link_gym_already_in_another_chain(): void
    {
        $this->superAdmin();
        $chain1 = GymChain::factory()->create();
        $chain2 = GymChain::factory()->create();
        $gym    = Gym::factory()->create(['chain_id' => $chain1->id]);

        $response = $this->postJson("/api/super/chains/{$chain2->id}/gyms", ['gym_id' => $gym->id]);
        $response->assertStatus(422);
        $response->assertJsonPath('message', 'Esta academia já pertence a outra rede.');

        $this->assertEquals($chain1->id, $gym->fresh()->chain_id, 'gym não deve ser movida');
    }

    // ── UNLINK ────────────────────────────────────────────────────────────────

    public function test_super_admin_can_unlink_gym_from_chain(): void
    {
        $this->superAdmin();
        $chain = GymChain::factory()->create();
        $gym   = Gym::factory()->create(['chain_id' => $chain->id]);

        $response = $this->deleteJson("/api/super/chains/{$chain->id}/gyms/{$gym->id}");
        $response->assertStatus(200);

        $this->assertNull($gym->fresh()->chain_id);
    }

    // ── AUTH ──────────────────────────────────────────────────────────────────

    public function test_non_super_admin_cannot_access_chain_endpoints(): void
    {
        $gym   = Gym::factory()->create();
        $admin = User::factory()->create(['gym_id' => $gym->id, 'role' => 'gym_admin']);
        Sanctum::actingAs($admin);

        $this->getJson('/api/super/chains')->assertStatus(403);
        $this->postJson('/api/super/chains', ['name' => 'X'])->assertStatus(403);
    }
}
