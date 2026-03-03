<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Gym;
use App\Models\ExerciseWeight;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class WeightTest extends TestCase
{
    use RefreshDatabase;

    private function createAuthUser(): array
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        return [$gym, $user];
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Append-only: nunca sobrescreve registro anterior
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function save_weight_creates_new_record_without_updating_previous()
    {
        [$gym, $user] = $this->createAuthUser();

        $exerciseId = 'exercise-abc';

        // Primeiro registro — set 1, 50 kg
        $this->putJson("/api/exercises/{$exerciseId}/weight/set", [
            'set_number' => 1,
            'weight'     => 50,
            'reps'       => 10,
        ])->assertStatus(201);

        // Segundo registro — mesma série, peso diferente
        $this->putJson("/api/exercises/{$exerciseId}/weight/set", [
            'set_number' => 1,
            'weight'     => 55,
            'reps'       => 8,
        ])->assertStatus(201);

        // Deve haver 2 registros (append-only), não 1
        $this->assertEquals(2,
            ExerciseWeight::where('user_id', $user->id)
                ->where('exercise_id', $exerciseId)
                ->where('set_number', 1)
                ->count()
        );
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Last: retorna peso mais recente por série
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function last_returns_most_recent_weight_per_set()
    {
        [$gym, $user] = $this->createAuthUser();

        $exerciseId = 'exercise-abc';

        // Set 1: dois registros — 50 e depois 55
        ExerciseWeight::create([
            'user_id' => $user->id, 'exercise_id' => $exerciseId,
            'set_number' => 1, 'weight' => 50, 'reps' => 10,
        ]);
        ExerciseWeight::create([
            'user_id' => $user->id, 'exercise_id' => $exerciseId,
            'set_number' => 1, 'weight' => 55, 'reps' => 8,
        ]);

        // Set 2: um registro — 60
        ExerciseWeight::create([
            'user_id' => $user->id, 'exercise_id' => $exerciseId,
            'set_number' => 2, 'weight' => 60, 'reps' => 6,
        ]);

        $response = $this->getJson("/api/exercises/{$exerciseId}/weight/last");

        $response->assertStatus(200);

        $data = $response->json();

        // Set 1 deve retornar 55 (mais recente), não 50
        $this->assertEquals(55, $data['1']);
        // Set 2 deve retornar 60
        $this->assertEquals(60, $data['2']);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // History: ordenado do mais recente para o mais antigo
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function history_returns_entries_ordered_newest_first()
    {
        [$gym, $user] = $this->createAuthUser();

        $exerciseId = 'exercise-abc';

        // Criar 3 registros e forçar timestamps distintos via update direto
        $r1 = ExerciseWeight::create([
            'user_id' => $user->id, 'exercise_id' => $exerciseId,
            'set_number' => 1, 'weight' => 40, 'reps' => 10,
        ]);
        ExerciseWeight::where('id', $r1->id)->update(['created_at' => now()->subDays(2)]);

        $r2 = ExerciseWeight::create([
            'user_id' => $user->id, 'exercise_id' => $exerciseId,
            'set_number' => 1, 'weight' => 45, 'reps' => 10,
        ]);
        ExerciseWeight::where('id', $r2->id)->update(['created_at' => now()->subDay()]);

        $r3 = ExerciseWeight::create([
            'user_id' => $user->id, 'exercise_id' => $exerciseId,
            'set_number' => 1, 'weight' => 50, 'reps' => 8,
        ]);
        // r3 mantém created_at = now()

        $response = $this->getJson("/api/exercises/{$exerciseId}/history?set_number=1");

        $response->assertStatus(200);

        $data = $response->json();

        $this->assertCount(3, $data);
        // Primeiro item deve ser o mais recente (50 kg)
        $this->assertEquals(50, $data[0]['weight']);
        // Último item deve ser o mais antigo (40 kg)
        $this->assertEquals(40, $data[2]['weight']);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Isolamento: usuário não pode ver pesos de outro usuário
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function user_cannot_see_another_users_weights()
    {
        $gym = Gym::factory()->create();

        $userA = User::factory()->create(['gym_id' => $gym->id]);
        $userB = User::factory()->create(['gym_id' => $gym->id]);

        $exerciseId = 'exercise-abc';

        // User A salva peso
        ExerciseWeight::create([
            'user_id' => $userA->id, 'exercise_id' => $exerciseId,
            'set_number' => 1, 'weight' => 100, 'reps' => 5,
        ]);

        // User B consulta — não deve ver os dados de A
        Sanctum::actingAs($userB);

        $responseLast = $this->getJson("/api/exercises/{$exerciseId}/weight/last");
        $responseLast->assertStatus(200);
        $this->assertEmpty((array) $responseLast->json());

        $responseHistory = $this->getJson("/api/exercises/{$exerciseId}/history");
        $responseHistory->assertStatus(200);
        $this->assertCount(0, $responseHistory->json());
    }
}
