<?php

namespace App\Services;

use App\Models\CustomWorkout;
use App\Models\User;
use App\Models\UserWorkoutPlan;
use App\Models\WorkoutExercise;
use App\Models\WorkoutPlan;
use App\Models\WorkoutPlanDay;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

// plano sempre determinado por day_of_week (0=Dom…6=Sáb), não por posição sequencial
class WorkoutPlanService
{
    public function __construct(private ExerciseOverrideService $overrideService)
    {
    }

    public function getTodayPlanForUser(User $user): ?array
    {
        $userPlan = UserWorkoutPlan::active()->where('user_id', $user->id)->first();

        if (! $userPlan) {
            return null;
        }

        $plan = WorkoutPlan::find($userPlan->plan_id);

        if (! $plan) {
            return null;
        }

        $todayDow = now()->dayOfWeek; // 0=Dom, 6=Sáb

        $today = WorkoutPlanDay::where('plan_id', $plan->id)
            ->where('day_of_week', $todayDow)
            ->first();

        // Carrega exercícios apenas se não for dia de descanso
        if ($today && ! $today->rest_day) {
            $today->load(['exercises.exercise']);

            $exerciseIds = $today->exercises
                ->pluck('exercise_id')
                ->filter()
                ->values()
                ->all();

            $overrides = $this->overrideService->loadOverridesForUser($user->id, $exerciseIds);
            $formattedDay = $this->formatDayForResponse($today, $overrides);
        } else {
            $formattedDay = $this->buildRestDayPayload($today, $todayDow);
        }

        return [
            'plan_id'                       => $plan->id,
            'plan_name'                     => $plan->name,
            'between_exercise_rest_seconds' => $plan->between_exercise_rest_seconds ?? 180,
            'today'                         => $formattedDay,
            'week_overview'                 => $this->buildWeekOverview($plan),
        ];
    }

    public function isOnPlanDay(User $user, Carbon $date): bool
    {
        $userPlan = UserWorkoutPlan::active()->where('user_id', $user->id)->first();

        if (! $userPlan) {
            return false;
        }

        return WorkoutPlanDay::where('plan_id', $userPlan->plan_id)
            ->where('day_of_week', $date->dayOfWeek)
            ->where('rest_day', false)
            ->exists();
    }

    // retorna: workout_day | rest_day | no_day | no_plan
    public function getPlanDayContext(User $user, Carbon $date): string
    {
        $userPlan = UserWorkoutPlan::active()->where('user_id', $user->id)->first();

        if (! $userPlan) {
            return 'no_plan';
        }

        $day = WorkoutPlanDay::where('plan_id', $userPlan->plan_id)
            ->where('day_of_week', $date->dayOfWeek)
            ->first();

        if ($day === null) {
            return 'no_day';
        }

        return $day->rest_day ? 'rest_day' : 'workout_day';
    }

    public function getWeekOverviewForUser(User $user): array
    {
        $userPlan = UserWorkoutPlan::active()->where('user_id', $user->id)->first();

        if (! $userPlan) {
            return $this->emptyWeekOverview();
        }

        $plan = WorkoutPlan::find($userPlan->plan_id);

        return $plan ? $this->buildWeekOverview($plan) : $this->emptyWeekOverview();
    }

    // se já tem plano ativo, o novo entra na próxima segunda (preserva streak em curso)
    public function assignPlanToUser(int $userId, int $planId, int $gymId): UserWorkoutPlan
    {
        $hasActivePlan = UserWorkoutPlan::active()->where('user_id', $userId)->exists();

        // Novo plano começa imediatamente se não há plano ativo;
        // caso contrário, entra em vigor na próxima segunda-feira.
        $effectiveFrom = $hasActivePlan
            ? Carbon::now()->next(Carbon::MONDAY)->toDateString()
            : now()->toDateString();

        return UserWorkoutPlan::updateOrCreate(
            ['user_id' => $userId],
            [
                'plan_id'        => $planId,
                'gym_id'         => $gymId,
                'started_at'     => now(),
                'effective_from' => $effectiveFrom,
            ]
        );
    }

    /**
     * Cria um dia do plano a partir de um template (CustomWorkout).
     * O dia resultante é independente — mudanças no template não afetam o plano.
     *
     * @param  int  $dow  day_of_week (0=Dom … 6=Sáb) — obrigatório para garantir
     *                    que o dia seja imediatamente visível nas queries do endpoint.
     */
    public function addDayFromTemplate(WorkoutPlan $plan, int $workoutId, int $dow): WorkoutPlanDay
    {
        $workout = CustomWorkout::with('exercises')
            ->where('is_template', true)
            ->findOrFail($workoutId);

        return DB::transaction(function () use ($plan, $workout, $dow) {
            $day = WorkoutPlanDay::create([
                'plan_id'     => $plan->id,
                'day_of_week' => $dow,
                'name'        => $workout->name,
                'rest_day'    => false,
            ]);

            foreach ($workout->exercises as $index => $exercise) {
                WorkoutExercise::create([
                    'plan_day_id'    => $day->id,
                    'exercise_id'    => $exercise->id,
                    'sets'           => $exercise->pivot->sets,
                    'reps'           => (string) $exercise->pivot->reps,
                    'rest_seconds'   => $exercise->pivot->rest,
                    'exercise_order' => $index + 1,
                    'technique'      => 'normal',
                ]);
            }

            return $day;
        });
    }

    /**
     * Formata um WorkoutPlanDay com exercícios para a resposta da API.
     */
    public function formatDayForResponse(WorkoutPlanDay $day, $overrides = null): array
    {
        if (! $day->relationLoaded('exercises')) {
            $day->load(['exercises.exercise']);
        }

        $overrides = $overrides ?? collect();

        $exercises = $day->exercises->map(function ($we) use ($overrides) {
            $ex       = $we->exercise;
            $override = $ex ? $overrides->get($ex->id) : null;

            if (! $ex) {
                return [
                    'id'               => $we->id,
                    'exercise_id'      => $we->exercise_id,
                    'name'             => '',
                    'muscle_group'     => '',
                    'image_url'        => null,
                    'video_url'        => null,
                    'description'      => null,
                    'execution_steps'  => [],
                    'common_mistakes'  => [],
                    'tips'             => [],
                    'primary_muscle'   => null,
                    'secondary_muscles'=> [],
                    'type'             => 'strength',
                    'sets'             => $we->sets,
                    'reps'             => $we->reps,
                    'rest_seconds'     => $we->rest_seconds,
                    'duration_minutes' => $we->duration_minutes,
                    'distance_km'      => $we->distance_km,
                    'technique'        => $we->technique ?? 'normal',
                    'group_id'         => $we->group_id,
                    'rounds'           => $we->rounds,
                    'drops'            => $we->drops,
                    'exercise_order'   => $we->exercise_order,
                    'default_rest'     => 60,
                    'has_override'     => false,
                ];
            }

            return array_merge(
                $this->overrideService->resolveForApi($ex, $override),
                [
                    'id'               => $we->id,
                    'exercise_id'      => $ex->id,
                    'sets'             => $we->sets,
                    'reps'             => $we->reps,
                    'rest_seconds'     => $we->rest_seconds,
                    'duration_minutes' => $we->duration_minutes,
                    'distance_km'      => $we->distance_km,
                    'technique'        => $we->technique ?? 'normal',
                    'group_id'         => $we->group_id,
                    'rounds'           => $we->rounds,
                    'drops'            => $we->drops,
                    'exercise_order'   => $we->exercise_order,
                ]
            );
        })->values()->all();

        return [
            'id'          => $day->id,
            'plan_id'     => $day->plan_id,
            'day_of_week' => $day->day_of_week,
            'name'        => $day->name,
            'rest_day'    => (bool) $day->rest_day,
            'exercises'   => $exercises,
        ];
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Helpers privados
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Constrói o resumo semanal de um plano (7 slots, 0=Dom a 6=Sáb).
     */
    private function buildWeekOverview(WorkoutPlan $plan): array
    {
        $days = WorkoutPlanDay::where('plan_id', $plan->id)->get()->keyBy('day_of_week');

        $overview = [];
        for ($dow = 0; $dow <= 6; $dow++) {
            $day           = $days->get($dow);
            $hasWorkout    = $day !== null && ! $day->rest_day;
            $overview[$dow] = [
                'day_of_week' => $dow,
                'has_workout' => $hasWorkout,
                'rest_day'    => ! $hasWorkout,
                'name'        => $day?->name ?? 'Descanso',
            ];
        }

        return $overview;
    }

    private function buildRestDayPayload(?WorkoutPlanDay $day, int $dow): array
    {
        return [
            'id'          => $day?->id,
            'plan_id'     => $day?->plan_id,
            'day_of_week' => $dow,
            'name'        => $day?->name ?? 'Descanso',
            'rest_day'    => true,
            'exercises'   => [],
        ];
    }

    private function emptyWeekOverview(): array
    {
        $overview = [];
        for ($dow = 0; $dow <= 6; $dow++) {
            $overview[$dow] = [
                'day_of_week' => $dow,
                'has_workout' => false,
                'rest_day'    => true,
                'name'        => 'Descanso',
            ];
        }
        return $overview;
    }
}
