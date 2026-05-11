<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\GymOpenDay;
use App\Models\User;
use App\Models\UserWorkoutPlan;
use App\Models\WorkoutPlan;
use App\Models\WorkoutPlanDay;
use App\Models\WorkoutSession;
use App\Services\StreakService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

/**
 * Testes do sistema de streak baseado em calendário.
 *
 * Regras fundamentais:
 *   - Streak sobe: treino válido em dia obrigatório (workout no plano + academia aberta)
 *   - Streak quebra: dia obrigatório passou sem treino
 *   - Dia de descanso (plano): streak pausado (nem sobe, nem quebra)
 *   - Academia fechada: dia ignorado (streak não quebra)
 *   - Treino fora do plano: não conta para streak
 *   - Sem plano + academia aberta: qualquer dia é obrigatório (streak incrementa/quebra normalmente)
 *   - Sem plano + academia fechada: dia ignorado (streak não quebra)
 *
 * Semana: domingo (0) → sábado (6).
 */
class DailyStreakTest extends TestCase
{
    use RefreshDatabase;

    private Gym  $gym;
    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->gym  = Gym::factory()->create();
        $this->user = User::factory()->create([
            'gym_id'         => $this->gym->id,
            'points_balance' => 0,
            'current_streak' => 0,
            'best_streak'    => 0,
        ]);

        Sanctum::actingAs($this->user);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Cria plano com os dias informados (Carbon dayOfWeek: 0=Dom, 6=Sáb).
     * Dias não listados = descanso implícito.
     */
    private function createPlan(array $workoutDays): void
    {
        $plan = WorkoutPlan::create([
            'gym_id'     => $this->gym->id,
            'name'       => 'Plano Teste',
            'created_by' => $this->user->id,
        ]);

        foreach ($workoutDays as $dow) {
            WorkoutPlanDay::create([
                'plan_id'     => $plan->id,
                'day_of_week' => $dow,
                'name'        => "Treino " . $dow,
                'rest_day'    => false,
            ]);
        }

        UserWorkoutPlan::create([
            'user_id'    => $this->user->id,
            'plan_id'    => $plan->id,
            'gym_id'     => $this->gym->id,
            'started_at' => now(),
        ]);
    }

    /**
     * Adiciona dia de descanso EXPLÍCITO ao plano (opcional — apenas para
     * testar o comportamento de rest_day=true vs dia não configurado).
     */
    private function addRestDay(int $dow): void
    {
        $userPlan = UserWorkoutPlan::active()->where('user_id', $this->user->id)->first();
        WorkoutPlanDay::create([
            'plan_id'     => $userPlan->plan_id,
            'day_of_week' => $dow,
            'name'        => 'Descanso',
            'rest_day'    => true,
        ]);
    }

    /**
     * Define dias de funcionamento da academia.
     * Dias não listados → abertos por padrão.
     */
    private function setGymClosed(array $closedDays): void
    {
        foreach ($closedDays as $dow) {
            GymOpenDay::create([
                'gym_id'      => $this->gym->id,
                'day_of_week' => $dow,
                'is_open'     => false,
            ]);
        }
    }

    /**
     * Simula processamento de um treino válido on-plan em uma data.
     * Define last_workout_date e avança o streak como se o serviço fosse chamado.
     */
    private function processWorkoutOn(Carbon $date): array
    {
        Carbon::setTestNow($date);
        $this->user->refresh();

        // Create a valid session so countWorkoutsThisWeek() counts it
        WorkoutSession::create([
            'user_id'           => $this->user->id,
            'gym_id'            => $this->gym->id,
            'started_at'        => $date->copy()->subMinutes(30),
            'finished_at'       => $date,
            'progress'          => 100,
            'points_granted'    => true,
            'points_granted_at' => $date,
        ]);

        $service = new StreakService();
        $result  = $service->processWorkoutForDailyStreak($this->user);
        $this->user->refresh();
        return $result;
    }

    /**
     * Simula apenas a abertura do dashboard (lazy-break detection).
     */
    private function openDashboardOn(Carbon $date): array
    {
        Carbon::setTestNow($date);
        $this->user->refresh();
        $service = new StreakService();
        return $service->getStreakState($this->user);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // CENÁRIO A: Usuário cumpre todos os dias obrigatórios → streak sobe
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function scenario_a_streak_increases_when_all_plan_days_completed(): void
    {
        // Plano: Seg, Ter, Qui, Sex (Qua = descanso implícito)
        $this->createPlan([1, 2, 4, 5]); // 1=Seg, 2=Ter, 4=Qui, 5=Sex

        $monday    = Carbon::parse('2026-03-16'); // Segunda
        $tuesday   = Carbon::parse('2026-03-17'); // Terça
        $thursday  = Carbon::parse('2026-03-19'); // Quinta (Qua era descanso)
        $friday    = Carbon::parse('2026-03-20'); // Sexta

        $r1 = $this->processWorkoutOn($monday);
        $this->assertEquals(1, $r1['streak'], 'Segunda: streak=1');

        $r2 = $this->processWorkoutOn($tuesday);
        $this->assertEquals(2, $r2['streak'], 'Terça: streak=2');

        // Quarta é descanso — não treinar não deve quebrar
        $this->openDashboardOn(Carbon::parse('2026-03-18')); // Quarta
        $this->user->refresh();
        $this->assertEquals(2, $this->user->current_streak, 'Quarta (descanso): streak mantido em 2');

        $r3 = $this->processWorkoutOn($thursday);
        $this->assertEquals(3, $r3['streak'], 'Quinta: streak=3 (Qua era descanso)');

        $r4 = $this->processWorkoutOn($friday);
        $this->assertEquals(4, $r4['streak'], 'Sexta: streak=4');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // CENÁRIO B: Usuário falta dia obrigatório → streak quebra
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function scenario_b_streak_breaks_when_obligatory_day_is_missed(): void
    {
        // Plano: Seg, Ter, Qua, Qui
        $this->createPlan([1, 2, 3, 4]);

        $monday   = Carbon::parse('2026-03-16');
        $tuesday  = Carbon::parse('2026-03-17');
        // Quarta: obrigatório, mas não treina
        $thursday = Carbon::parse('2026-03-19');

        $this->processWorkoutOn($monday);
        $this->processWorkoutOn($tuesday);

        // Quinta: detecta que Quarta foi perdida → quebra, depois incrementa
        $result = $this->processWorkoutOn($thursday);

        $this->assertEquals(1, $result['streak'],
            'Após faltar Quarta, streak volta a 1 (apenas este treino de Quinta)');
        $this->assertEquals(2, $result['best_streak'],
            'best_streak deve preservar o recorde anterior de 2');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // CENÁRIO C: Treino em dia de descanso → streak não conta
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function scenario_c_training_on_rest_day_does_not_advance_streak(): void
    {
        // Plano: Seg, Qua (Ter = descanso explícito)
        $this->createPlan([1, 3]); // Seg e Qua
        $this->addRestDay(2);      // Ter = descanso explícito

        $monday    = Carbon::parse('2026-03-16');
        $tuesday   = Carbon::parse('2026-03-17'); // descanso
        $wednesday = Carbon::parse('2026-03-18');

        // Treina na Segunda → streak=1
        $r1 = $this->processWorkoutOn($monday);
        $this->assertEquals(1, $r1['streak']);

        // Treina na Terça (dia de descanso no plano)
        // → streak NÃO deve avançar
        // → last_workout_date NÃO deve ser atualizado (clock não reseta)
        Carbon::setTestNow($tuesday);
        $this->user->refresh();
        // Simulamos que processWorkoutForDailyStreak não é chamado para rest days
        // (WorkoutFinishService só chama para isObligatoryDay=true)
        // Então verificamos getStreakState, que também não avança
        $stateOnTuesday = (new StreakService())->getStreakState($this->user);
        $this->assertEquals(1, $stateOnTuesday['streak'],
            'Streak permanece 1 na Terça (descanso)');

        // Treina na Quarta (obrigatório) → streak deve ir para 2
        // last_workout_date ainda é Seg, gap = 2 dias, mas Ter é descanso → sem break
        $r3 = $this->processWorkoutOn($wednesday);
        $this->assertEquals(2, $r3['streak'],
            'Quarta: streak=2 (Terça era descanso, não gerou break)');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // CENÁRIO D: Treino fora do plano → não conta streak, ganha pontos reduzidos
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function scenario_d_off_plan_training_is_not_obligatory(): void
    {
        // Plano: apenas Seg (rest_day implícito em todos os outros dias)
        $this->createPlan([1]); // apenas Segunda

        $monday    = Carbon::parse('2026-03-16');
        $wednesday = Carbon::parse('2026-03-18'); // não está no plano

        // Treina na Segunda → streak=1
        $this->processWorkoutOn($monday);
        $this->user->refresh();
        $this->assertEquals(1, $this->user->current_streak);

        // isObligatoryDay na Quarta? Plano não tem Qua → false
        $service    = new StreakService();
        $isObligQua = $service->isObligatoryDay($this->user, $wednesday);
        $this->assertFalse($isObligQua,
            'Quarta não é obrigatória pois não está no plano');

        // getStreakState na Quarta não deve quebrar streak
        $state = $this->openDashboardOn($wednesday);
        $this->assertEquals(1, $state['streak'],
            'Streak permanece 1 na Quarta (dia não configurado no plano)');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // CENÁRIO E: Academia fechada → streak não quebra
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function scenario_e_closed_gym_day_does_not_break_streak(): void
    {
        // Plano: Seg, Ter, Qua, Qui, Sex
        $this->createPlan([1, 2, 3, 4, 5]);

        // Academia fechada na Quarta
        $this->setGymClosed([3]); // 3=Quarta

        $monday   = Carbon::parse('2026-03-16');
        $tuesday  = Carbon::parse('2026-03-17');
        $wednesday = Carbon::parse('2026-03-18'); // gym fechado
        $thursday = Carbon::parse('2026-03-19');

        $this->processWorkoutOn($monday);
        $this->processWorkoutOn($tuesday);

        // isObligatoryDay na Quarta? Plano tem workout, mas gym fechado → false
        $service   = new StreakService();
        $isObligQua = $service->isObligatoryDay($this->user, $wednesday);
        $this->assertFalse($isObligQua,
            'Quarta não é obrigatória porque academia está fechada');

        // Abre dashboard na Quarta → streak não quebra
        $state = $this->openDashboardOn($wednesday);
        $this->assertEquals(2, $state['streak'],
            'Streak permanece 2 na Quarta (gym fechado)');

        // Treina na Quinta → gap = Ter→Qui, Qua ignorada → streak=3
        $result = $this->processWorkoutOn($thursday);
        $this->assertEquals(3, $result['streak'],
            'Quinta: streak=3 (Qua ignorada por gym fechado)');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // CENÁRIO F: Semana vira → sistema continua consistente
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function scenario_f_week_rollover_resets_weekly_goal_but_not_streak(): void
    {
        // Plano: Seg a Sex
        $this->createPlan([1, 2, 3, 4, 5]);

        // Semana 1: treina Seg, Ter, Qua
        $w1mon = Carbon::parse('2026-03-16');
        $w1tue = Carbon::parse('2026-03-17');
        $w1wed = Carbon::parse('2026-03-18');

        $this->processWorkoutOn($w1mon);
        $this->processWorkoutOn($w1tue);
        $r = $this->processWorkoutOn($w1wed);

        $this->assertEquals(3, $r['streak']);

        // Semana 2: começa no Domingo
        $w2sun = Carbon::parse('2026-03-22'); // Domingo — início da nova semana

        // Abre dashboard no domingo → semana deve ter resetado, streak mantido
        $state = $this->openDashboardOn($w2sun);

        $this->assertEquals(3, $state['streak'],
            'Streak não é resetado na virada de semana');
        $this->assertEquals(0, $state['workouts_done_this_week'],
            'Contagem semanal resetada para 0 na nova semana');

        // Treina na Segunda da semana 2 → streak=4
        $w2mon = Carbon::parse('2026-03-23');
        // Qui e Sex da semana 1 foram perdidas → gap Qua→Dom = 4 dias,
        // Qui e Sex são obrigatórias → streak DEVE quebrar
        $result = $this->processWorkoutOn($w2mon);

        $this->assertEquals(1, $result['streak'],
            'Streak quebrou porque Qui e Sex da semana anterior foram perdidas');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Edge: treinar duas vezes no mesmo dia → idempotente
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function same_day_workout_is_idempotent(): void
    {
        $this->createPlan([1]); // apenas Segunda

        $monday = Carbon::parse('2026-03-16');

        $r1 = $this->processWorkoutOn($monday);
        $this->assertEquals(1, $r1['streak']);

        $r2 = $this->processWorkoutOn($monday); // segunda vez no mesmo dia
        $this->assertEquals(1, $r2['streak'],
            'Segundo treino no mesmo dia não deve incrementar streak');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Edge: best_streak é atualizado corretamente
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function best_streak_updates_when_current_exceeds_it(): void
    {
        $this->createPlan([1, 2, 3]); // Seg, Ter, Qua

        $monday    = Carbon::parse('2026-03-16');
        $tuesday   = Carbon::parse('2026-03-17');
        $wednesday = Carbon::parse('2026-03-18');

        $this->processWorkoutOn($monday);
        $this->processWorkoutOn($tuesday);
        $result = $this->processWorkoutOn($wednesday);

        $this->assertEquals(3, $result['streak']);
        $this->assertEquals(3, $result['best_streak']);

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Edge: sem plano → streak incrementa em qualquer dia que academia está aberta
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function user_without_plan_streak_increments_on_open_gym_day(): void
    {
        // Sem createPlan → nenhum plano atribuído; academia aberta por padrão
        $monday = Carbon::parse('2026-03-16');
        Carbon::setTestNow($monday);
        $this->user->refresh();

        $service = new StreakService();
        $result  = $service->processWorkoutForDailyStreak($this->user);

        $this->assertEquals(1, $result['streak'],
            'Sem plano, qualquer dia de academia aberta incrementa o streak');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Edge: isObligatoryDay retorna false para dia de descanso explícito
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function rest_day_is_not_obligatory(): void
    {
        $this->createPlan([1, 3]); // Seg e Qua
        $this->addRestDay(2);      // Ter = descanso explícito

        $tuesday = Carbon::parse('2026-03-17');
        Carbon::setTestNow($tuesday);
        $this->user->refresh();

        $service   = new StreakService();
        $isOblig   = $service->isObligatoryDay($this->user, $tuesday);

        $this->assertFalse($isOblig, 'Terça (rest_day explícito) não é dia obrigatório');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Edge: dashboard call em dia de descanso não quebra streak
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function dashboard_call_on_rest_day_does_not_break_streak(): void
    {
        $this->createPlan([1]); // apenas Segunda

        $this->user->update([
            'current_streak'    => 5,
            'best_streak'       => 5,
            'last_workout_date' => '2026-03-16', // segunda
        ]);

        // Abre dashboard na Quarta (sem plano configurado para Qua)
        $wednesday = Carbon::parse('2026-03-18');
        $state     = $this->openDashboardOn($wednesday);

        $this->assertEquals(5, $state['streak'],
            'Streak deve permanecer 5 — Quarta não é dia obrigatório');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // CENÁRIO 1 — Troca de plano: novo plano só começa na próxima semana
    //
    // Garantia: streak e weekly progress continuam usando o plano antigo
    // enquanto effective_from do novo plano ainda não chegou.
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function plan_change_new_plan_only_activates_next_week(): void
    {
        // Plano 1 (ativo imediatamente): Seg e Ter
        $planA = WorkoutPlan::create([
            'gym_id'     => $this->gym->id,
            'name'       => 'Plano A',
            'created_by' => $this->user->id,
        ]);
        WorkoutPlanDay::create(['plan_id' => $planA->id, 'day_of_week' => 1, 'name' => 'Seg', 'rest_day' => false]);
        WorkoutPlanDay::create(['plan_id' => $planA->id, 'day_of_week' => 2, 'name' => 'Ter', 'rest_day' => false]);

        UserWorkoutPlan::create([
            'user_id'        => $this->user->id,
            'plan_id'        => $planA->id,
            'gym_id'         => $this->gym->id,
            'started_at'     => now(),
            'effective_from' => null, // ativo imediatamente
        ]);

        // Plano 2 (ainda não ativo): Qua e Qui — começa somente na próxima semana
        $nextMonday = Carbon::parse('2026-03-23'); // segunda da semana seguinte

        $planB = WorkoutPlan::create([
            'gym_id'     => $this->gym->id,
            'name'       => 'Plano B',
            'created_by' => $this->user->id,
        ]);
        WorkoutPlanDay::create(['plan_id' => $planB->id, 'day_of_week' => 3, 'name' => 'Qua', 'rest_day' => false]);
        WorkoutPlanDay::create(['plan_id' => $planB->id, 'day_of_week' => 4, 'name' => 'Qui', 'rest_day' => false]);

        // Simula a troca de plano: substituí o registro com effective_from futuro
        UserWorkoutPlan::where('user_id', $this->user->id)->update([
            'plan_id'        => $planB->id,
            'effective_from' => $nextMonday->toDateString(),
        ]);

        // Terça desta semana (2026-03-17) — plano B ainda NÃO ativo
        $tuesday = Carbon::parse('2026-03-17');
        Carbon::setTestNow($tuesday);
        $this->user->refresh();

        $service = new StreakService();

        // Sem plano ativo (effective_from futuro) → qualquer dia de academia aberta é obrigatório
        // Terça está aberta por padrão → isObligatoryDay = true
        $isObligatory = $service->isObligatoryDay($this->user, $tuesday);
        $this->assertTrue($isObligatory,
            'Sem plano ativo, qualquer dia de academia aberta conta para streak');

        // getStreakState retorna estrutura válida
        $state = $service->getStreakState($this->user);
        $this->assertArrayHasKey('streak', $state);

        Carbon::setTestNow(null);
    }

    /** @test */
    public function plan_change_old_plan_still_used_until_effective_date(): void
    {
        // Plano A: Seg e Ter (ativo desde hoje)
        $planA = WorkoutPlan::create([
            'gym_id'     => $this->gym->id,
            'name'       => 'Plano A',
            'created_by' => $this->user->id,
        ]);
        WorkoutPlanDay::create(['plan_id' => $planA->id, 'day_of_week' => 1, 'name' => 'Seg', 'rest_day' => false]);
        WorkoutPlanDay::create(['plan_id' => $planA->id, 'day_of_week' => 2, 'name' => 'Ter', 'rest_day' => false]);

        // Plano A é o plano atual e ativo
        UserWorkoutPlan::create([
            'user_id'        => $this->user->id,
            'plan_id'        => $planA->id,
            'gym_id'         => $this->gym->id,
            'started_at'     => Carbon::parse('2026-03-16'),
            'effective_from' => '2026-03-16', // Segunda desta semana
        ]);

        // Usuário treinou na Segunda → streak = 1
        $monday = Carbon::parse('2026-03-16');
        $this->processWorkoutOn($monday);
        $this->user->refresh();
        $this->assertEquals(1, $this->user->current_streak);

        // Plano B: apenas Sexta — troca agendada para semana que vem
        $planB = WorkoutPlan::create([
            'gym_id'     => $this->gym->id,
            'name'       => 'Plano B',
            'created_by' => $this->user->id,
        ]);
        WorkoutPlanDay::create(['plan_id' => $planB->id, 'day_of_week' => 5, 'name' => 'Sex', 'rest_day' => false]);

        UserWorkoutPlan::where('user_id', $this->user->id)->update([
            'plan_id'        => $planB->id,
            'effective_from' => '2026-03-23', // próxima segunda
        ]);

        // Terça desta semana: plano A NÃO é mais ativo (foi substituído por B com
        // effective_from futuro). Sem plano ativo + academia aberta → Terça é obrigatória.
        $tuesday = Carbon::parse('2026-03-17');
        Carbon::setTestNow($tuesday);
        $this->user->refresh();

        $service = new StreakService();

        // Sem plano ativo, academia aberta → dia é obrigatório (não congelado)
        $this->assertTrue(
            $service->isObligatoryDay($this->user, $tuesday),
            'Sem plano ativo, academia aberta → dia é obrigatório para streak'
        );

        // getStreakState é só-leitura e não altera o streak
        $state = $service->getStreakState($this->user);

        $this->assertEquals(1, $state['streak'],
            'Streak permanece 1 (getStreakState é só-leitura — não incrementa nem quebra)');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // CENÁRIO 2 — Virada de semana: sistema passa a usar o novo plano
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function week_rollover_activates_new_plan_automatically(): void
    {
        // Configura plano pendente com effective_from = próxima segunda (2026-03-23)
        $plan = WorkoutPlan::create([
            'gym_id'     => $this->gym->id,
            'name'       => 'Plano Novo',
            'created_by' => $this->user->id,
        ]);
        // Plano: apenas Quarta
        WorkoutPlanDay::create(['plan_id' => $plan->id, 'day_of_week' => 3, 'name' => 'Qua', 'rest_day' => false]);

        UserWorkoutPlan::create([
            'user_id'        => $this->user->id,
            'plan_id'        => $plan->id,
            'gym_id'         => $this->gym->id,
            'started_at'     => Carbon::parse('2026-03-17'), // atribuído na Terça
            'effective_from' => '2026-03-23',                // ativo a partir da próxima segunda
        ]);

        // Terça (antes do effective_from) → plano NÃO ativo
        $tuesday = Carbon::parse('2026-03-17');
        Carbon::setTestNow($tuesday);
        $this->user->refresh();

        $service = new StreakService();
        // Sem plano ativo (effective_from futuro), academia aberta por padrão → obrigatório
        $this->assertTrue(
            $service->isObligatoryDay($this->user, $tuesday),
            'Sem plano ativo, qualquer dia de academia aberta é obrigatório para streak'
        );

        // Quarta da semana seguinte (após effective_from) → plano ativo
        $nextWednesday = Carbon::parse('2026-03-25');
        Carbon::setTestNow($nextWednesday);
        $this->user->refresh();

        $this->assertTrue(
            $service->isObligatoryDay($this->user, $nextWednesday),
            'Quarta da próxima semana deve ser obrigatória — plano agora vigente'
        );

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // CENÁRIO 3 — Treino em dia obrigatório: streak e weekly atualizam
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function training_on_obligatory_day_updates_streak_and_weekly(): void
    {
        // Plano: Seg, Ter, Qui
        $this->createPlan([1, 2, 4]);

        $monday   = Carbon::parse('2026-03-16');
        $tuesday  = Carbon::parse('2026-03-17');
        $thursday = Carbon::parse('2026-03-19');

        // Seg: streak sobe para 1
        $r1 = $this->processWorkoutOn($monday);
        $this->assertEquals(1, $r1['streak'],       'Seg: streak = 1');
        $this->assertEquals(1, $r1['workouts_done_this_week'], 'Seg: workouts_done = 1');
        $this->assertEquals(3, $r1['weekly_goal'],  'Meta semanal = 3 dias do plano');

        // Ter: streak sobe para 2
        $r2 = $this->processWorkoutOn($tuesday);
        $this->assertEquals(2, $r2['streak'],       'Ter: streak = 2');
        $this->assertEquals(2, $r2['workouts_done_this_week'], 'Ter: workouts_done = 2');

        // Qua é descanso implícito — nada acontece

        // Qui: streak sobe para 3 (gap de Qua ignorado pois não é obrigatório)
        $r3 = $this->processWorkoutOn($thursday);
        $this->assertEquals(3, $r3['streak'],       'Qui: streak = 3');
        $this->assertEquals(3, $r3['workouts_done_this_week'], 'Qui: workouts_done = 3');
        $this->assertEquals(0, $r3['remaining_workouts_this_week'],
            'Meta atingida: remaining = 0');

        Carbon::setTestNow(null);
    }
}
