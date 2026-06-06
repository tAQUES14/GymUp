<?php

namespace Tests\Feature;

use App\Models\CustomWorkout;
use App\Models\Exercise;
use App\Models\Gym;
use App\Models\User;
use App\Models\UserWorkoutPlan;
use App\Models\WorkoutPlan;
use App\Models\WorkoutPlanDay;
use App\Services\WorkoutPlanService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WorkoutGymIsolationTest extends TestCase
{
    use RefreshDatabase;

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function makeGym(): Gym
    {
        return Gym::factory()->create();
    }

    /** Admin/trainer that bypasses permission checks (super_admin role). */
    private function makeAdmin(Gym $gym): User
    {
        return User::factory()->create([
            'gym_id' => $gym->id,
            'role'   => 'super_admin',
        ]);
    }

    private function makeStudent(Gym $gym): User
    {
        return User::factory()->create([
            'gym_id' => $gym->id,
            'role'   => 'user',
        ]);
    }

    private function makeTemplate(Gym $gym, User $creator): CustomWorkout
    {
        return CustomWorkout::create([
            'user_id'      => $creator->id,
            'gym_id'       => $gym->id,
            'name'         => 'Treino ' . $gym->id,
            'is_template'  => true,
            'is_generated' => false,
        ]);
    }

    private function makePlan(Gym $gym): WorkoutPlan
    {
        return WorkoutPlan::create([
            'gym_id' => $gym->id,
            'name'   => 'Plano ' . $gym->id,
        ]);
    }

    private function makeExercise(): Exercise
    {
        return Exercise::create([
            'name'         => 'Agachamento',
            'type'         => 'strength',
            'muscle_group' => 'legs',
        ]);
    }

    // ── Test 1: aluno só vê treinos da própria academia ──────────────────────

    /** @test */
    public function student_only_sees_own_gym_plan_today()
    {
        $gymA = $this->makeGym();
        $gymB = $this->makeGym();

        $student = $this->makeStudent($gymA);
        $admin   = $this->makeAdmin($gymA);

        $planA = $this->makePlan($gymA);
        $planB = $this->makePlan($gymB);

        // Dia de treino na segunda para o plano A
        WorkoutPlanDay::create([
            'plan_id'     => $planA->id,
            'day_of_week' => now()->dayOfWeek,
            'name'        => 'Perna',
            'rest_day'    => false,
        ]);

        // Atribui plano A ao aluno (da academia A)
        UserWorkoutPlan::create([
            'user_id'        => $student->id,
            'plan_id'        => $planA->id,
            'gym_id'         => $gymA->id,
            'started_at'     => now(),
            'effective_from' => now()->toDateString(),
        ]);

        $service = app(WorkoutPlanService::class);

        // Aluno recebe plano A normalmente
        $result = $service->getTodayPlanForUser($student);
        $this->assertNotNull($result);
        $this->assertEquals($planA->id, $result['plan_id']);

        // Se tentarmos fabricar um UserWorkoutPlan apontando para plano B (outra academia),
        // o service deve retornar null (plano não pertence à academia do aluno)
        UserWorkoutPlan::where('user_id', $student->id)->update(['plan_id' => $planB->id]);

        $result = $service->getTodayPlanForUser($student);
        $this->assertNull($result, 'Plano de outra academia nao deve ser retornado para o aluno.');
    }

    // ── Test 2: admin só lista treinos da própria academia ───────────────────

    /** @test */
    public function admin_only_lists_workouts_from_own_gym()
    {
        $gymA = $this->makeGym();
        $gymB = $this->makeGym();

        $adminA  = $this->makeAdmin($gymA);
        $adminB  = $this->makeAdmin($gymB);

        $this->makeTemplate($gymA, $adminA);
        $this->makeTemplate($gymA, $adminA);
        $this->makeTemplate($gymB, $adminB);

        Sanctum::actingAs($adminA);
        $response = $this->getJson('/api/admin/workouts');

        $response->assertStatus(200);
        $workouts = $response->json('workouts');

        $this->assertCount(2, $workouts, 'Admin de A deve ver apenas os 2 treinos da academia A.');

        $gymIds = collect($workouts)->pluck('id')->toArray();

        // Verify none of the IDs belong to gymB's template
        $gymBTemplateId = CustomWorkout::where('gym_id', $gymB->id)->first()->id;
        $this->assertNotContains($gymBTemplateId, $gymIds, 'Treino da academia B nao deve aparecer para admin da academia A.');
    }

    // ── Test 3: admin de uma academia não acessa treinos de outra ────────────

    /** @test */
    public function admin_cannot_access_workout_from_another_gym()
    {
        $gymA = $this->makeGym();
        $gymB = $this->makeGym();

        $adminA = $this->makeAdmin($gymA);
        $adminB = $this->makeAdmin($gymB);

        $templateB = $this->makeTemplate($gymB, $adminB);

        Sanctum::actingAs($adminA);

        // GET detalhe de treino da academia B → 404
        $this->getJson("/api/admin/workouts/{$templateB->id}")
            ->assertStatus(404);

        // PUT update treino da academia B → 404
        $this->putJson("/api/admin/workouts/{$templateB->id}", ['name' => 'Hack'])
            ->assertStatus(404);

        // DELETE treino da academia B → 404
        $this->deleteJson("/api/admin/workouts/{$templateB->id}")
            ->assertStatus(404);
    }

    // ── Test 4: treino criado pelo painel salva gym_id correto ───────────────

    /** @test */
    public function store_workout_saves_correct_gym_id()
    {
        $gymA  = $this->makeGym();
        $admin = $this->makeAdmin($gymA);
        $ex    = $this->makeExercise();

        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/admin/workouts', [
            'name'      => 'Treino Costas',
            'exercises' => [
                [
                    'exercise_id' => $ex->id,
                    'sets'        => 3,
                    'reps'        => 12,
                    'rest'        => 60,
                ],
            ],
        ]);

        $response->assertStatus(201);

        $workout = CustomWorkout::where('name', 'Treino Costas')->first();

        $this->assertNotNull($workout, 'Treino deve ter sido criado no banco.');
        $this->assertEquals($gymA->id, $workout->gym_id, 'gym_id deve corresponder à academia do admin.');
        $this->assertTrue($workout->is_template, 'Treino criado pelo admin deve ser template.');
    }

    // ── Test 5: endpoint de treino do dia respeita academia do aluno ─────────

    /** @test */
    public function today_plan_endpoint_respects_student_gym()
    {
        $gymA = $this->makeGym();
        $gymB = $this->makeGym();

        $student = $this->makeStudent($gymA);
        $adminB  = $this->makeAdmin($gymB);

        $planA = $this->makePlan($gymA);
        $planB = $this->makePlan($gymB);

        $dow = now()->dayOfWeek;

        WorkoutPlanDay::create([
            'plan_id'     => $planA->id,
            'day_of_week' => $dow,
            'name'        => 'Peito',
            'rest_day'    => false,
        ]);

        WorkoutPlanDay::create([
            'plan_id'     => $planB->id,
            'day_of_week' => $dow,
            'name'        => 'Costas',
            'rest_day'    => false,
        ]);

        // Atribui plano correto (academia A)
        UserWorkoutPlan::create([
            'user_id'        => $student->id,
            'plan_id'        => $planA->id,
            'gym_id'         => $gymA->id,
            'started_at'     => now(),
            'effective_from' => now()->toDateString(),
        ]);

        Sanctum::actingAs($student);

        // Com plano correto — deve retornar o plano da academia A
        $response = $this->getJson('/api/workout-plan/today');
        $response->assertStatus(200);
        $this->assertEquals($planA->id, $response->json('plan_id'));

        // Substitui plano pelo da academia B (injeção de plano estrangeiro)
        UserWorkoutPlan::where('user_id', $student->id)->update(['plan_id' => $planB->id]);

        // Deve retornar 404 / dados vazios — plano não pertence à academia do aluno
        $response = $this->getJson('/api/workout-plan/today');
        // O endpoint pode retornar 200 com null ou 404 conforme implementação —
        // o importante é que o plan_id da academia B nunca apareça.
        if ($response->status() === 200) {
            $this->assertNull(
                $response->json('plan_id'),
                'plan_id da academia B nao deve aparecer para aluno da academia A.'
            );
        } else {
            $response->assertStatus(404);
        }
    }
}
