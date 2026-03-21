<?php

namespace Tests\Feature;

use App\Models\Exercise;
use App\Models\Gym;
use App\Models\User;
use App\Models\WorkoutPlan;
use App\Models\WorkoutPlanDay;
use App\Models\WorkoutExercise;
use App\Models\UserWorkoutPlan;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WorkoutPlanCardioTest extends TestCase
{
    use RefreshDatabase;

    private function createAuthUser(string $role = 'user'): array
    {
        $gym = Gym::create(['name' => 'Test Gym', 'slug' => 'test-gym']);
        $user = User::create([
            'name'     => 'Test User',
            'email'    => 'user@test.com',
            'password' => bcrypt('password'),
            'gym_id'   => $gym->id,
            'role'     => $role,
        ]);
        return [$gym, $user];
    }

    /** @test */
    public function cardio_exercise_has_correct_type(): void
    {
        $treadmill = Exercise::create([
            'name'         => 'Esteira',
            'type'         => 'cardio',
            'muscle_group' => 'Cardio',
            'default_rest' => 0,
        ]);

        $this->assertEquals('cardio', $treadmill->type);
    }

    /** @test */
    public function strength_exercise_defaults_to_strength_type(): void
    {
        $bench = Exercise::create([
            'name'         => 'Supino Reto',
            'muscle_group' => 'Peito',
            'default_rest' => 90,
        ]);

        // type column defaults to 'strength' at the DB level
        $this->assertEquals('strength', $bench->fresh()->type);
    }

    /** @test */
    public function plan_day_can_include_cardio_exercise_with_duration(): void
    {
        [$gym, $user] = $this->createAuthUser();

        $cardioEx = Exercise::create([
            'name'         => 'Bike Ergométrica',
            'type'         => 'cardio',
            'muscle_group' => 'Cardio',
            'default_rest' => 0,
        ]);

        $plan = WorkoutPlan::create([
            'gym_id' => $gym->id,
            'name'   => 'Treino Misto',
        ]);

        $day = WorkoutPlanDay::create([
            'plan_id'   => $plan->id,
            'day_order' => 1,
            'name'      => 'Cardio Day',
            'rest_day'  => false,
        ]);

        $we = WorkoutExercise::create([
            'plan_day_id'      => $day->id,
            'exercise_id'      => $cardioEx->id,
            'sets'             => null,
            'reps'             => null,
            'rest_seconds'     => 0,
            'exercise_order'   => 1,
            'duration_minutes' => 20,
            'distance_km'      => 5.0,
        ]);

        $this->assertNull($we->sets);
        $this->assertNull($we->reps);
        $this->assertEquals(20, $we->duration_minutes);
        $this->assertEquals(5.0, $we->distance_km);
    }

    /** @test */
    public function today_endpoint_returns_cardio_fields_in_response(): void
    {
        [$gym, $user] = $this->createAuthUser();

        $strengthEx = Exercise::create([
            'name'         => 'Supino Reto',
            'type'         => 'strength',
            'muscle_group' => 'Peito',
            'default_rest' => 90,
        ]);

        $cardioEx = Exercise::create([
            'name'         => 'Esteira',
            'type'         => 'cardio',
            'muscle_group' => 'Cardio',
            'default_rest' => 0,
        ]);

        $plan = WorkoutPlan::create([
            'gym_id' => $gym->id,
            'name'   => 'Push + Cardio',
        ]);

        $day = WorkoutPlanDay::create([
            'plan_id'   => $plan->id,
            'day_order' => 1,
            'name'      => 'Push',
            'rest_day'  => false,
        ]);

        WorkoutExercise::create([
            'plan_day_id'    => $day->id,
            'exercise_id'    => $strengthEx->id,
            'sets'           => 4,
            'reps'           => '8',
            'rest_seconds'   => 90,
            'exercise_order' => 1,
        ]);

        WorkoutExercise::create([
            'plan_day_id'      => $day->id,
            'exercise_id'      => $cardioEx->id,
            'sets'             => null,
            'reps'             => null,
            'rest_seconds'     => 0,
            'exercise_order'   => 2,
            'duration_minutes' => 15,
            'distance_km'      => null,
        ]);

        UserWorkoutPlan::create([
            'user_id'           => $user->id,
            'plan_id'           => $plan->id,
            'gym_id'            => $gym->id,
            'current_day_index' => 1,
            'started_at'        => now(),
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/workout-plan/today');

        $response->assertOk()
            ->assertJsonPath('current_day.name', 'Push')
            ->assertJsonPath('current_day.rest_day', false);

        $exercises = $response->json('current_day.exercises');
        $this->assertCount(2, $exercises);

        // Strength exercise
        $this->assertEquals('strength', $exercises[0]['type']);
        $this->assertEquals(4, $exercises[0]['sets']);
        $this->assertEquals('8', $exercises[0]['reps']);
        $this->assertNull($exercises[0]['duration_minutes']);

        // Cardio exercise
        $this->assertEquals('cardio', $exercises[1]['type']);
        $this->assertNull($exercises[1]['sets']);
        $this->assertNull($exercises[1]['reps']);
        $this->assertEquals(15, $exercises[1]['duration_minutes']);
        $this->assertNull($exercises[1]['distance_km']);
    }

    /** @test */
    public function admin_can_create_exercise_with_cardio_type(): void
    {
        [$gym, $admin] = $this->createAuthUser('super_admin');

        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/admin/exercises', [
            'name'         => 'Corda',
            'type'         => 'cardio',
            'muscle_group' => 'Cardio',
            'default_rest' => 30,
        ]);

        $response->assertCreated()
            ->assertJsonPath('exercise.type', 'cardio')
            ->assertJsonPath('exercise.name', 'Corda');
    }

    /** @test */
    public function admin_can_add_cardio_day_to_plan_via_api(): void
    {
        [$gym, $admin] = $this->createAuthUser('super_admin');

        $cardioEx = Exercise::create([
            'name'         => 'Elíptico',
            'type'         => 'cardio',
            'muscle_group' => 'Cardio',
            'default_rest' => 0,
        ]);

        $plan = WorkoutPlan::create([
            'gym_id' => $gym->id,
            'name'   => 'Plano Teste',
        ]);

        Sanctum::actingAs($admin);

        $response = $this->postJson("/api/admin/workout-plans/{$plan->id}/days", [
            'name'     => 'Cardio Light',
            'rest_day' => false,
            'exercises' => [
                [
                    'exercise_id'      => $cardioEx->id,
                    'duration_minutes' => 30,
                    'distance_km'      => 3.5,
                    'rest_seconds'     => 0,
                    'exercise_order'   => 1,
                ],
            ],
        ]);

        $response->assertCreated();

        $exercises = $response->json('day.exercises');
        $this->assertCount(1, $exercises);
        $this->assertEquals('cardio', $exercises[0]['type']);
        $this->assertEquals(30, $exercises[0]['duration_minutes']);
        $this->assertEquals(3.5, $exercises[0]['distance_km']);
        $this->assertNull($exercises[0]['sets']);
    }
}
