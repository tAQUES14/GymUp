<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Checkin;
use App\Models\ChallengeParticipant;
use App\Models\CustomWorkout;
use App\Models\Exercise;
use App\Models\Gym;
use App\Models\GymChallenge;
use App\Models\User;
use App\Models\UserWorkoutPlan;
use App\Models\WorkoutPlan;
use App\Models\WorkoutPlanDay;
use App\Models\WorkoutSession;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

/**
 * Valida o fluxo completo de treino criado pelo próprio aluno.
 *
 * Premissas verificadas:
 *   - is_template = false, template_id = null  → treino de autoria do aluno
 *   - Não aparece em AdminWorkoutController (filtra is_template = true)
 *   - Pontos e desafios processados normalmente
 *   - Streak: congelado sem plano, incrementado com plano no dia correto
 */
class UserCreatedWorkoutFlowTest extends TestCase
{
    use RefreshDatabase;

    // ──────────────────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────────────────

    private function createUserWithCheckin(array $userAttrs = []): array
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(array_merge([
            'gym_id'         => $gym->id,
            'points_balance' => 0,
            'current_streak' => 0,
            'best_streak'    => 0,
        ], $userAttrs));
        Sanctum::actingAs($user);

        Checkin::factory()->create([
            'user_id'      => $user->id,
            'gym_id'       => $gym->id,
            'checkin_date' => now()->toDateString(),
        ]);

        return [$gym, $user];
    }

    private function createExercise(Gym $gym): Exercise
    {
        return Exercise::create([
            'name'         => 'Supino Reto',
            'muscle_group' => 'Peito',
            'type'         => 'strength',
            'default_rest' => 60,
            'gym_id'       => $gym->id,
        ]);
    }

    /** Cria um treino de aluno (is_template=false, template_id=null) via API. */
    private function createStudentWorkout(Exercise $exercise): CustomWorkout
    {
        $response = $this->postJson('/api/custom-workouts', [
            'name'         => 'Meu Treino Pessoal',
            'description'  => '',
            'duration'     => 45,
            'level'        => 'intermediate',
            'is_generated' => false,
            'exercises'    => [
                [
                    'exercise_id' => $exercise->id,
                    'sets'        => 3,
                    'reps'        => 12,
                    'rest'        => 60,
                ],
            ],
        ]);

        $response->assertStatus(201);

        return CustomWorkout::latest()->first();
    }

    /** Cria uma sessão ativa e a finaliza com dados válidos (retorna a response). */
    private function startAndFinishSession(User $user, Gym $gym): \Illuminate\Testing\TestResponse
    {
        WorkoutSession::factory()->create([
            'user_id'    => $user->id,
            'gym_id'     => $gym->id,
            'started_at' => now()->subMinutes(15),
            'progress'   => 0,
        ]);

        return $this->postJson('/api/workout/finish', [
            'completion_percent' => 80,
            'duration_seconds'   => 900,
        ]);
    }

    private function createSimpleChallenge(Gym $gym): GymChallenge
    {
        return GymChallenge::create([
            'gym_id'        => $gym->id,
            'type'          => 'simple',
            'name'          => 'Desafio Teste',
            'starts_at'     => now()->toDateString(),
            'ends_at'       => now()->addDays(30)->toDateString(),
            'status'        => 'active',
            'goal_workouts' => 5,
            'reward_points' => 200,
        ]);
    }

    /** Atribui um plano com treino no dia de hoje ao usuário. */
    private function assignPlanWithTodayAsWorkoutDay(User $user, Gym $gym): void
    {
        $plan = WorkoutPlan::create([
            'gym_id'     => $gym->id,
            'name'       => 'Plano Teste',
            'created_by' => $user->id,
        ]);

        WorkoutPlanDay::create([
            'plan_id'     => $plan->id,
            'day_of_week' => now()->dayOfWeek,
            'name'        => 'Treino hoje',
            'rest_day'    => false,
        ]);

        UserWorkoutPlan::create([
            'user_id'    => $user->id,
            'plan_id'    => $plan->id,
            'gym_id'     => $gym->id,
            'started_at' => now(),
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Testes
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function student_workout_is_created_with_correct_source_flags()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        $exercise = $this->createExercise($gym);
        $workout  = $this->createStudentWorkout($exercise);

        $this->assertFalse($workout->is_template);
        $this->assertNull($workout->template_id);
        $this->assertEquals($user->id, $workout->user_id);

        Carbon::setTestNow();
    }

    /** @test */
    public function finishing_valid_session_grants_points_regardless_of_workout_source()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        $exercise = $this->createExercise($gym);
        $this->createStudentWorkout($exercise);

        $response = $this->startAndFinishSession($user, $gym);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');
        $response->assertJsonPath('points_generated', 10);

        $session = WorkoutSession::where('user_id', $user->id)->latest()->first();
        $this->assertTrue($session->points_granted);

        $user->refresh();
        $this->assertEquals(10, $user->points_balance);

        Carbon::setTestNow();
    }

    /** @test */
    public function without_plan_streak_increments_on_any_open_gym_day()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        $exercise = $this->createExercise($gym);
        $this->createStudentWorkout($exercise);

        $response = $this->startAndFinishSession($user, $gym);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');
        $response->assertJsonPath('points_generated', 10);
        $response->assertJsonPath('streak_just_increased', true);

        $user->refresh();
        $this->assertEquals(10, $user->points_balance);
        $this->assertGreaterThanOrEqual(1, $user->current_streak);

        Carbon::setTestNow();
    }

    /** @test */
    public function with_plan_streak_increments_on_valid_workout_day()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        $this->assignPlanWithTodayAsWorkoutDay($user, $gym);

        $exercise = $this->createExercise($gym);
        $this->createStudentWorkout($exercise);

        $response = $this->startAndFinishSession($user, $gym);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');
        $response->assertJsonPath('streak_just_increased', true);

        $user->refresh();
        $this->assertGreaterThanOrEqual(1, $user->current_streak);

        Carbon::setTestNow();
    }

    /** @test */
    public function finishing_workout_increments_challenge_participant_progress()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        $challenge = $this->createSimpleChallenge($gym);

        $exercise = $this->createExercise($gym);
        $this->createStudentWorkout($exercise);

        $response = $this->startAndFinishSession($user, $gym);

        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');

        $participant = ChallengeParticipant::where('challenge_id', $challenge->id)
            ->where('user_id', $user->id)
            ->first();

        $this->assertNotNull($participant);
        $this->assertEquals(1, $participant->workouts_this_challenge);

        Carbon::setTestNow();
    }

    /** @test */
    public function student_workout_does_not_appear_in_admin_panel()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        $exercise = $this->createExercise($gym);
        $workout  = $this->createStudentWorkout($exercise);

        // Finaliza uma sessão para garantir que o treino passou pelo pipeline completo.
        $this->startAndFinishSession($user, $gym);

        // Autentica como admin para consultar o painel.
        $admin = User::factory()->create(['gym_id' => $gym->id, 'role' => 'super_admin']);
        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/workouts');

        $response->assertStatus(200);
        $response->assertJsonStructure(['workouts']);

        $workoutNames = collect($response->json('workouts'))->pluck('name');
        $this->assertNotContains($workout->name, $workoutNames->all());

        Carbon::setTestNow();
    }

    /** @test */
    public function full_e2e_student_creates_starts_and_finishes_workout()
    {
        Carbon::setTestNow(Carbon::now());
        [$gym, $user] = $this->createUserWithCheckin();

        $challenge = $this->createSimpleChallenge($gym);
        $exercise  = $this->createExercise($gym);

        // 1. Aluno cria o treino.
        $workout = $this->createStudentWorkout($exercise);
        $this->assertFalse($workout->is_template);
        $this->assertNull($workout->template_id);

        // 2. Inicia e finaliza a sessão.
        $response = $this->startAndFinishSession($user, $gym);
        $response->assertStatus(200);
        $response->assertJsonPath('status', 'VALID');
        $response->assertJsonPath('points_generated', 10);

        // 3. Sessão marcada como points_granted = true.
        $session = WorkoutSession::where('user_id', $user->id)->latest()->first();
        $this->assertTrue($session->points_granted);

        // 4. Saldo do usuário aumentou.
        $user->refresh();
        $this->assertEquals(10, $user->points_balance);

        // 5. Progresso no desafio incrementado.
        $participant = ChallengeParticipant::where('challenge_id', $challenge->id)
            ->where('user_id', $user->id)
            ->first();
        $this->assertNotNull($participant);
        $this->assertEquals(1, $participant->workouts_this_challenge);

        // 6. Treino não aparece no painel admin.
        $admin = User::factory()->create(['gym_id' => $gym->id, 'role' => 'super_admin']);
        Sanctum::actingAs($admin);

        $adminResponse = $this->getJson('/api/admin/workouts');
        $adminResponse->assertStatus(200);

        $workoutNames = collect($adminResponse->json('workouts'))->pluck('name');
        $this->assertNotContains($workout->name, $workoutNames->all());

        Carbon::setTestNow();
    }
}
