<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\User;
use App\Models\UserGoal;
use App\Services\GoalService;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class GoalTest extends TestCase
{
    use RefreshDatabase;

    private function createAuthUser(): array
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);
        Sanctum::actingAs($user);

        return [$gym, $user];
    }

    private function basePayload(array $overrides = []): array
    {
        return array_merge([
            'goal_type'      => 'weight_loss',
            'gender'         => 'male',
            'start_weight'   => 95,
            'target_weight'  => 90,
            'height'         => 175,
            'age'            => 30,
            'activity_level' => 'moderate',
            'target_months'  => 3,
        ], $overrides);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GoalService unit: BMR (Mifflin-St Jeor)
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function bmr_is_calculated_correctly_for_male()
    {
        $service = new GoalService();
        // BMR = (10×90) + (6.25×175) − (5×30) + 5 = 900 + 1093.75 − 150 + 5 = 1848.75
        $result = $service->calculateBMR(90, 175, 30, 'male');
        $this->assertEqualsWithDelta(1848.75, $result, 0.01);
    }

    /** @test */
    public function bmr_is_calculated_correctly_for_female()
    {
        $service = new GoalService();
        // BMR = (10×65) + (6.25×162) − (5×25) − 161 = 650 + 1012.5 − 125 − 161 = 1376.5
        $result = $service->calculateBMR(65, 162, 25, 'female');
        $this->assertEqualsWithDelta(1376.5, $result, 0.01);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GoalService unit: TDEE
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function tdee_applies_correct_multiplier_for_moderate()
    {
        $service = new GoalService();
        $tdee    = $service->calculateTDEE(1800.0, 'moderate');
        $this->assertEqualsWithDelta(1800 * 1.55, $tdee, 0.01);
    }

    /** @test */
    public function tdee_applies_correct_multiplier_for_sedentary()
    {
        $service = new GoalService();
        $tdee    = $service->calculateTDEE(2000.0, 'sedentary');
        $this->assertEqualsWithDelta(2000.0 * 1.2, $tdee, 0.01);
    }

    /** @test */
    public function tdee_applies_correct_multiplier_for_intense()
    {
        $service = new GoalService();
        $tdee    = $service->calculateTDEE(1600.0, 'intense');
        $this->assertEqualsWithDelta(1600.0 * 1.725, $tdee, 0.01);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GoalService unit: daily deficit
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function daily_deficit_is_calculated_correctly_for_weight_loss()
    {
        $service = new GoalService();
        // |95−90| × 7700 / (3×30) = 38500 / 90 = 427.77... → 428
        $result = $service->calculateDailyDeficit(95, 90, 3);
        $this->assertEquals(428, $result);
    }

    /** @test */
    public function daily_deficit_uses_absolute_delta_for_weight_gain()
    {
        $service = new GoalService();
        // |70−75| × 7700 / (2×30) = 38500 / 60 = 641.66... → 642
        $result = $service->calculateDailyDeficit(70, 75, 2);
        $this->assertEquals(642, $result);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/goals — cria meta com sucesso
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function user_can_create_a_weight_loss_goal()
    {
        [$gym, $user] = $this->createAuthUser();

        $response = $this->postJson('/api/goals', $this->basePayload());

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'goal_type',
            'gender',
            'start_weight',
            'target_weight',
            'height',
            'age',
            'activity_level',
            'target_months',
            'estimated_daily_calorie_deficit',
            'estimated_workouts_per_week',
            'created_at',
        ]);
        $response->assertJsonFragment(['goal_type' => 'weight_loss']);
        $response->assertJsonFragment(['estimated_workouts_per_week' => 4]);

        $this->assertDatabaseHas('user_goals', [
            'user_id'   => $user->id,
            'goal_type' => 'weight_loss',
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Uma meta ativa por usuário: nova meta substitui a anterior
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function creating_a_new_goal_replaces_the_previous_one()
    {
        [$gym, $user] = $this->createAuthUser();

        $this->postJson('/api/goals', $this->basePayload())->assertStatus(201);
        $this->postJson('/api/goals', $this->basePayload(['target_weight' => 85]))->assertStatus(201);

        $this->assertEquals(1, UserGoal::where('user_id', $user->id)->count());
        $this->assertEquals(85, (float) UserGoal::where('user_id', $user->id)->first()->target_weight);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GET /api/goals/current
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function user_can_get_current_goal()
    {
        [$gym, $user] = $this->createAuthUser();

        UserGoal::create([
            'user_id'                         => $user->id,
            'goal_type'                       => 'weight_loss',
            'gender'                          => 'female',
            'start_weight'                    => 70,
            'target_weight'                   => 65,
            'height'                          => 162,
            'age'                             => 25,
            'activity_level'                  => 'light',
            'target_months'                   => 2,
            'estimated_daily_calorie_deficit' => 642,
            'estimated_workouts_per_week'     => 3,
        ]);

        $response = $this->getJson('/api/goals/current');

        $response->assertStatus(200);
        $response->assertJsonFragment(['goal_type' => 'weight_loss']);
        $response->assertJsonFragment(['gender'    => 'female']);
        $response->assertJsonFragment(['estimated_workouts_per_week' => 3]);
    }

    /** @test */
    public function get_current_goal_returns_404_when_no_goal_exists()
    {
        [$gym, $user] = $this->createAuthUser();

        $this->getJson('/api/goals/current')->assertStatus(404);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Isolamento: usuário não acessa a meta de outro usuário
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function user_cannot_see_another_users_goal()
    {
        $gym   = Gym::factory()->create();
        $userA = User::factory()->create(['gym_id' => $gym->id]);
        $userB = User::factory()->create(['gym_id' => $gym->id]);

        UserGoal::create([
            'user_id'                         => $userA->id,
            'goal_type'                       => 'weight_loss',
            'gender'                          => 'male',
            'start_weight'                    => 90,
            'target_weight'                   => 85,
            'height'                          => 175,
            'age'                             => 28,
            'activity_level'                  => 'moderate',
            'target_months'                   => 3,
            'estimated_daily_calorie_deficit' => 428,
            'estimated_workouts_per_week'     => 4,
        ]);

        Sanctum::actingAs($userB);

        $this->getJson('/api/goals/current')->assertStatus(404);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Meta de consistência: deficit deve ser null
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function consistency_goal_has_null_calorie_deficit()
    {
        [$gym, $user] = $this->createAuthUser();

        $response = $this->postJson('/api/goals', $this->basePayload([
            'goal_type'     => 'consistency',
            'start_weight'  => 80,
            'target_weight' => 80,
        ]));

        $response->assertStatus(201);
        $this->assertNull($response->json('estimated_daily_calorie_deficit'));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Validação de entrada
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function creating_goal_without_required_fields_returns_422()
    {
        [$gym, $user] = $this->createAuthUser();

        $this->postJson('/api/goals', [])->assertStatus(422);
    }

    /** @test */
    public function creating_goal_with_invalid_goal_type_returns_422()
    {
        [$gym, $user] = $this->createAuthUser();

        $this->postJson('/api/goals', $this->basePayload(['goal_type' => 'diet']))->assertStatus(422);
    }

    /** @test */
    public function creating_goal_with_invalid_activity_level_returns_422()
    {
        [$gym, $user] = $this->createAuthUser();

        $this->postJson('/api/goals', $this->basePayload(['activity_level' => 'extreme']))->assertStatus(422);
    }
}
