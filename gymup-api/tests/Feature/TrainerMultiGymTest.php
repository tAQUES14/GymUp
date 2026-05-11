<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\GymChain;
use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

class TrainerMultiGymTest extends TestCase
{
    use RefreshDatabase;

    // ──────────────────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Cria um trainer e configura o RBAC mínimo para que ele possa
     * acessar /admin/users (permission: view_users).
     */
    private function createTrainer(int $gymId, array $overrides = []): User
    {
        $trainer = User::factory()->create(array_merge(
            ['gym_id' => $gymId, 'role' => 'trainer'],
            $overrides
        ));

        $role = Role::firstOrCreate(['name' => 'trainer', 'gym_id' => null]);
        $perm = Permission::firstOrCreate(['name' => 'view_users', 'description' => 'View students']);
        $role->permissions()->syncWithoutDetaching([$perm->id]);
        $trainer->roles()->syncWithoutDetaching([$role->id]);

        return $trainer;
    }

    /**
     * Vincula um trainer a uma filial via trainer_gyms.
     */
    private function linkTrainerToGym(User $trainer, Gym $gym, bool $isPrimary = false): void
    {
        \Illuminate\Support\Facades\DB::table('trainer_gyms')->insertOrIgnore([
            'trainer_id' => $trainer->id,
            'gym_id'     => $gym->id,
            'is_primary' => $isPrimary,
            'created_at' => now(),
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 1. Trainer com uma filial funciona como antes
    // ──────────────────────────────────────────────────────────────────────────

    public function test_trainer_with_single_gym_works_as_before(): void
    {
        $gym     = Gym::factory()->create();
        $trainer = $this->createTrainer($gym->id);
        $this->linkTrainerToGym($trainer, $gym, isPrimary: true);

        // Cria um aluno na mesma filial
        User::factory()->create(['gym_id' => $gym->id, 'role' => 'user']);

        Sanctum::actingAs($trainer);

        // activeGymId() sem active_gym_id → cai em gym_id → filial padrão
        $this->assertEquals($gym->id, $trainer->activeGymId());

        $response = $this->getJson('/api/admin/users');
        $response->assertStatus(200)
            ->assertJsonCount(1, 'users');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 2. Trainer com múltiplas filiais lista todas
    // ──────────────────────────────────────────────────────────────────────────

    public function test_trainer_with_multiple_gyms_lists_all_gyms(): void
    {
        $gymA    = Gym::factory()->create();
        $gymB    = Gym::factory()->create();
        $trainer = $this->createTrainer($gymA->id);
        $this->linkTrainerToGym($trainer, $gymA, isPrimary: true);
        $this->linkTrainerToGym($trainer, $gymB, isPrimary: false);

        Sanctum::actingAs($trainer);

        $response = $this->getJson('/api/trainer/gyms');
        $response->assertStatus(200);

        $gyms = $response->json('gyms');
        $this->assertCount(2, $gyms);

        $primaryGym = collect($gyms)->firstWhere('id', $gymA->id);
        $this->assertTrue($primaryGym['is_primary']);

        $secondaryGym = collect($gyms)->firstWhere('id', $gymB->id);
        $this->assertFalse($secondaryGym['is_primary']);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 3. Trainer pode trocar para filial vinculada
    // ──────────────────────────────────────────────────────────────────────────

    public function test_trainer_can_switch_to_linked_gym(): void
    {
        $gymA    = Gym::factory()->create();
        $gymB    = Gym::factory()->create();
        $trainer = $this->createTrainer($gymA->id);
        $this->linkTrainerToGym($trainer, $gymA, isPrimary: true);
        $this->linkTrainerToGym($trainer, $gymB, isPrimary: false);

        Sanctum::actingAs($trainer);

        $response = $this->postJson('/api/trainer/switch-gym', ['gym_id' => $gymB->id]);
        $response->assertStatus(200)
            ->assertJsonPath('active_gym_id', $gymB->id)
            ->assertJsonPath('gym.id', $gymB->id);

        $trainer->refresh();
        $this->assertEquals($gymB->id, $trainer->active_gym_id);
        $this->assertEquals($gymB->id, $trainer->activeGymId());
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 4. Trainer não pode trocar para filial sem vínculo → 403
    // ──────────────────────────────────────────────────────────────────────────

    public function test_trainer_cannot_switch_to_unlinked_gym(): void
    {
        $gymA    = Gym::factory()->create();
        $gymB    = Gym::factory()->create(); // sem vínculo
        $trainer = $this->createTrainer($gymA->id);
        $this->linkTrainerToGym($trainer, $gymA, isPrimary: true);

        Sanctum::actingAs($trainer);

        $this->postJson('/api/trainer/switch-gym', ['gym_id' => $gymB->id])
            ->assertStatus(403)
            ->assertJsonFragment(['message' => 'Você não está vinculado a esta filial.']);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 5. Trainer só vê alunos da filial ativa
    // ──────────────────────────────────────────────────────────────────────────

    public function test_trainer_only_sees_students_of_active_gym(): void
    {
        $gymA    = Gym::factory()->create();
        $gymB    = Gym::factory()->create();
        $trainer = $this->createTrainer($gymA->id);
        $this->linkTrainerToGym($trainer, $gymA, isPrimary: true);
        $this->linkTrainerToGym($trainer, $gymB, isPrimary: false);

        // 2 alunos em gymA, 2 em gymB
        User::factory()->count(2)->create(['gym_id' => $gymA->id, 'role' => 'user']);
        User::factory()->count(2)->create(['gym_id' => $gymB->id, 'role' => 'user']);

        Sanctum::actingAs($trainer);

        // Antes do switch: vê alunos de gymA
        $this->getJson('/api/admin/users')
            ->assertStatus(200)
            ->assertJsonCount(2, 'users');

        // Troca para gymB
        $this->postJson('/api/trainer/switch-gym', ['gym_id' => $gymB->id])
            ->assertStatus(200);

        // Após o switch: trainer.active_gym_id = gymB → vê alunos de gymB
        $trainer->refresh();

        // Reseta o user na sessão para refletir o active_gym_id atualizado
        Sanctum::actingAs($trainer);

        $this->getJson('/api/admin/users')
            ->assertStatus(200)
            ->assertJsonCount(2, 'users');

        // Confirma que os alunos são todos de gymB
        $users = $this->getJson('/api/admin/users')->json('users');
        $gymBStudentIds = User::where('gym_id', $gymB->id)->where('role', 'user')->pluck('id')->toArray();
        foreach ($users as $u) {
            $this->assertContains($u['id'], $gymBStudentIds);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 6. Trainer não pode acessar dados de outra rede → 403 no switch-gym
    // ──────────────────────────────────────────────────────────────────────────

    public function test_trainer_cannot_access_other_chain_data(): void
    {
        $chain1 = GymChain::factory()->create();
        $chain2 = GymChain::factory()->create();

        $gymA = Gym::factory()->create(['chain_id' => $chain1->id]);
        $gymB = Gym::factory()->create(['chain_id' => $chain2->id]); // rede diferente

        $trainer = $this->createTrainer($gymA->id);
        $this->linkTrainerToGym($trainer, $gymA, isPrimary: true);
        // Trainer NÃO está vinculado a gymB

        Sanctum::actingAs($trainer);

        // Tentativa de switch para filial de outra rede → bloqueado
        $this->postJson('/api/trainer/switch-gym', ['gym_id' => $gymB->id])
            ->assertStatus(403)
            ->assertJsonFragment(['message' => 'Você não está vinculado a esta filial.']);
    }
}
