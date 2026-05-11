<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\GymChain;
use App\Models\User;
use App\Models\WorkoutSession;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class NetworkAdminUsersTest extends TestCase
{
    use RefreshDatabase;

    private function actingAsTrainer(Gym $gym): User
    {
        $trainer = User::factory()->create(['gym_id' => $gym->id, 'role' => 'super_admin']);
        Sanctum::actingAs($trainer);
        return $trainer;
    }

    private function checkinAt(User $user, int $gymId): void
    {
        WorkoutSession::factory()->create([
            'user_id'        => $user->id,
            'gym_id'         => $user->gym_id,
            'checkin_gym_id' => $gymId,
            'finished_at'    => now(),
            'points_granted' => true,
        ]);
    }

    public function test_admin_lists_own_students_without_visitors_when_no_chain(): void
    {
        $gym1    = Gym::factory()->create(['chain_id' => null]);
        $gym2    = Gym::factory()->create(['chain_id' => null]);
        $student = User::factory()->create(['gym_id' => $gym1->id, 'role' => 'user']);
        $other   = User::factory()->create(['gym_id' => $gym2->id, 'role' => 'user']);

        // other checks in to gym1 but they share no chain
        $this->checkinAt($other, $gym1->id);

        $this->actingAsTrainer($gym1);

        $response = $this->getJson('/api/admin/users');
        $response->assertStatus(200);

        $ids = array_column($response->json('users'), 'id');
        $this->assertContains($student->id, $ids);
        $this->assertNotContains($other->id, $ids, 'Usuário de academia independente não deve aparecer mesmo com check-in');

        $row = collect($response->json('users'))->firstWhere('id', $student->id);
        $this->assertFalse($row['is_visitor']);
    }

    public function test_admin_lists_own_students_and_visitors_from_same_chain(): void
    {
        $chain   = GymChain::factory()->create();
        $gym1    = Gym::factory()->create(['chain_id' => $chain->id]);
        $gym2    = Gym::factory()->create(['chain_id' => $chain->id]);
        $student = User::factory()->create(['gym_id' => $gym1->id, 'role' => 'user']);
        $visitor = User::factory()->create(['gym_id' => $gym2->id, 'role' => 'user']);

        // visitor treinou em gym1
        $this->checkinAt($visitor, $gym1->id);

        $this->actingAsTrainer($gym1);

        $response = $this->getJson('/api/admin/users');
        $response->assertStatus(200);

        $ids = array_column($response->json('users'), 'id');
        $this->assertContains($student->id, $ids, 'Aluno próprio deve aparecer');
        $this->assertContains($visitor->id, $ids, 'Visitante da mesma rede deve aparecer');

        $visitorRow = collect($response->json('users'))->firstWhere('id', $visitor->id);
        $this->assertTrue($visitorRow['is_visitor']);

        $studentRow = collect($response->json('users'))->firstWhere('id', $student->id);
        $this->assertFalse($studentRow['is_visitor']);
    }

    public function test_admin_does_not_list_visitors_from_different_chain(): void
    {
        $chain1  = GymChain::factory()->create();
        $chain2  = GymChain::factory()->create();
        $gym1    = Gym::factory()->create(['chain_id' => $chain1->id]);
        $gym2    = Gym::factory()->create(['chain_id' => $chain2->id]);
        $student = User::factory()->create(['gym_id' => $gym1->id, 'role' => 'user']);
        $foreign = User::factory()->create(['gym_id' => $gym2->id, 'role' => 'user']);

        // foreign checks in at gym1, but belongs to a different chain
        $this->checkinAt($foreign, $gym1->id);

        $this->actingAsTrainer($gym1);

        $response = $this->getJson('/api/admin/users');
        $response->assertStatus(200);

        $ids = array_column($response->json('users'), 'id');
        $this->assertNotContains($foreign->id, $ids, 'Usuário de rede diferente não deve aparecer');
    }

    public function test_visitor_flag_includes_home_gym_name(): void
    {
        $chain   = GymChain::factory()->create();
        $gym1    = Gym::factory()->create(['chain_id' => $chain->id, 'name' => 'Filial Centro']);
        $gym2    = Gym::factory()->create(['chain_id' => $chain->id, 'name' => 'Filial Norte']);
        $visitor = User::factory()->create(['gym_id' => $gym2->id, 'role' => 'user']);

        $this->checkinAt($visitor, $gym1->id);

        $this->actingAsTrainer($gym1);

        // Test via list
        $response = $this->getJson('/api/admin/users');
        $response->assertStatus(200);
        $visitorRow = collect($response->json('users'))->firstWhere('id', $visitor->id);
        $this->assertTrue($visitorRow['is_visitor']);
        $this->assertEquals('Filial Norte', $visitorRow['home_gym_name']);

        // Test via show
        $showResponse = $this->getJson("/api/admin/users/{$visitor->id}");
        $showResponse->assertStatus(200);
        $showResponse->assertJsonPath('is_visitor', true);
        $showResponse->assertJsonPath('home_gym_name', 'Filial Norte');
    }

    public function test_admin_cannot_modify_visitor_student(): void
    {
        $chain   = GymChain::factory()->create();
        $gym1    = Gym::factory()->create(['chain_id' => $chain->id]);
        $gym2    = Gym::factory()->create(['chain_id' => $chain->id]);
        $visitor = User::factory()->create(['gym_id' => $gym2->id, 'role' => 'user']);

        $this->checkinAt($visitor, $gym1->id);

        $this->actingAsTrainer($gym1);

        $this->putJson("/api/admin/users/{$visitor->id}", ['name' => 'Novo Nome'])
            ->assertStatus(403);

        $this->deleteJson("/api/admin/users/{$visitor->id}")
            ->assertStatus(403);

        $this->postJson("/api/admin/users/{$visitor->id}/adjust-points", [
            'points'      => 10,
            'description' => 'Teste',
        ])->assertStatus(403);
    }
}
