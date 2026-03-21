<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\WorkoutExercise;
use App\Models\WorkoutPlan;
use App\Models\WorkoutPlanDay;
use App\Services\WorkoutPlanService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminWorkoutPlanController extends Controller
{
    public function __construct(private WorkoutPlanService $planService)
    {
    }

    /**
     * GET /api/admin/workout-plans
     */
    public function index(Request $request): JsonResponse
    {
        $gymId = $request->user()->gym_id;

        $plans = WorkoutPlan::where('gym_id', $gymId)
            ->withCount('days')
            ->orderBy('name')
            ->get()
            ->map(fn ($p) => [
                'id'               => $p->id,
                'name'             => $p->name,
                'description'      => $p->description,
                'days_count'       => $p->days_count,
                'active_week_days' => $p->active_week_days ?? [],
                'created_at'       => $p->created_at->toIso8601String(),
            ]);

        return response()->json(['plans' => $plans]);
    }

    /**
     * POST /api/admin/workout-plans
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'                           => 'required|string|max:255',
            'description'                    => 'nullable|string',
            'between_exercise_rest_seconds'  => 'nullable|integer|min:0|max:600',
            'active_week_days'               => 'nullable|array',
            'active_week_days.*'             => 'integer|min:0|max:6',
        ]);

        $plan = WorkoutPlan::create([
            'gym_id'                         => $request->user()->gym_id,
            'name'                           => $request->name,
            'description'                    => $request->description,
            'between_exercise_rest_seconds'  => $request->input('between_exercise_rest_seconds', 180),
            'active_week_days'               => $request->input('active_week_days'),
            'created_by'                     => $request->user()->id,
        ]);

        return response()->json(['plan' => $plan], 201);
    }

    /**
     * GET /api/admin/workout-plans/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $gymId = $request->user()->gym_id;

        $plan = WorkoutPlan::where('gym_id', $gymId)
            ->with(['days' => function ($q) {
                $q->orderBy('day_order')->with(['exercises.exercise']);
            }])
            ->find($id);

        if (!$plan) {
            return response()->json(['message' => 'Plano não encontrado.'], 404);
        }

        $planData = [
            'id'                             => $plan->id,
            'name'                           => $plan->name,
            'description'                    => $plan->description,
            'between_exercise_rest_seconds'  => $plan->between_exercise_rest_seconds ?? 180,
            'active_week_days'               => $plan->active_week_days ?? [],
            'created_at'                     => $plan->created_at->toIso8601String(),
            'days'                           => $plan->days->map(fn ($d) => $this->planService->formatDayForResponse($d))->values(),
        ];

        return response()->json(['plan' => $planData]);
    }

    /**
     * PUT /api/admin/workout-plans/{id}
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'name'                           => 'sometimes|required|string|max:255',
            'description'                    => 'nullable|string',
            'between_exercise_rest_seconds'  => 'nullable|integer|min:0|max:600',
            'active_week_days'               => 'nullable|array',
            'active_week_days.*'             => 'integer|min:0|max:6',
        ]);

        $gymId = $request->user()->gym_id;

        $plan = WorkoutPlan::where('gym_id', $gymId)->find($id);

        if (!$plan) {
            return response()->json(['message' => 'Plano não encontrado.'], 404);
        }

        $plan->update($request->only(['name', 'description', 'between_exercise_rest_seconds', 'active_week_days']));

        return response()->json(['plan' => $plan]);
    }

    /**
     * DELETE /api/admin/workout-plans/{id}
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $gymId = $request->user()->gym_id;

        $plan = WorkoutPlan::where('gym_id', $gymId)->find($id);

        if (!$plan) {
            return response()->json(['message' => 'Plano não encontrado.'], 404);
        }

        $plan->delete();

        return response()->json(['message' => 'Plano excluído com sucesso.']);
    }

    /**
     * POST /api/admin/workout-plans/{id}/days
     */
    public function addDay(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'name'                           => 'required|string|max:255',
            'rest_day'                       => 'boolean',
            'exercises'                      => 'nullable|array',
            'exercises.*.exercise_id'        => 'required_unless:rest_day,true|integer|exists:exercises,id',
            'exercises.*.sets'               => 'nullable|integer|min:1',
            'exercises.*.reps'               => 'nullable|string',
            'exercises.*.rest_seconds'       => 'nullable|integer|min:0',
            'exercises.*.exercise_order'     => 'nullable|integer|min:1',
            'exercises.*.duration_minutes'   => 'nullable|integer|min:1',
            'exercises.*.distance_km'        => 'nullable|numeric|min:0',
            'exercises.*.technique'          => 'nullable|in:normal,superset,dropset,circuit',
            'exercises.*.group_id'           => 'nullable|integer|min:1',
            'exercises.*.rounds'             => 'nullable|integer|min:1',
            'exercises.*.drops'              => 'nullable|integer|min:1',
        ]);

        $gymId = $request->user()->gym_id;

        $plan = WorkoutPlan::where('gym_id', $gymId)->find($id);

        if (!$plan) {
            return response()->json(['message' => 'Plano não encontrado.'], 404);
        }

        $maxOrder = WorkoutPlanDay::where('plan_id', $plan->id)->max('day_order') ?? 0;

        $day = DB::transaction(function () use ($request, $plan, $maxOrder) {
            $day = WorkoutPlanDay::create([
                'plan_id'   => $plan->id,
                'day_order' => $maxOrder + 1,
                'name'      => $request->name,
                'rest_day'  => $request->boolean('rest_day', false),
            ]);

            $this->syncDayExercises($day, $request->input('exercises', []));

            return $day;
        });

        $day->load(['exercises.exercise']);

        return response()->json(['day' => $this->planService->formatDayForResponse($day)], 201);
    }

    /**
     * PUT /api/admin/workout-plans/{planId}/days/{dayId}
     */
    public function updateDay(Request $request, int $planId, int $dayId): JsonResponse
    {
        $request->validate([
            'name'                           => 'sometimes|required|string|max:255',
            'rest_day'                       => 'boolean',
            'exercises'                      => 'nullable|array',
            'exercises.*.exercise_id'        => 'required|integer|exists:exercises,id',
            'exercises.*.sets'               => 'nullable|integer|min:1',
            'exercises.*.reps'               => 'nullable|string',
            'exercises.*.rest_seconds'       => 'nullable|integer|min:0',
            'exercises.*.exercise_order'     => 'nullable|integer|min:1',
            'exercises.*.duration_minutes'   => 'nullable|integer|min:1',
            'exercises.*.distance_km'        => 'nullable|numeric|min:0',
            'exercises.*.technique'          => 'nullable|in:normal,superset,dropset,circuit',
            'exercises.*.group_id'           => 'nullable|integer|min:1',
            'exercises.*.rounds'             => 'nullable|integer|min:1',
            'exercises.*.drops'              => 'nullable|integer|min:1',
        ]);

        $gymId = $request->user()->gym_id;

        $plan = WorkoutPlan::where('gym_id', $gymId)->find($planId);

        if (!$plan) {
            return response()->json(['message' => 'Plano não encontrado.'], 404);
        }

        $day = WorkoutPlanDay::where('plan_id', $planId)->find($dayId);

        if (!$day) {
            return response()->json(['message' => 'Dia não encontrado.'], 404);
        }

        DB::transaction(function () use ($request, $day) {
            $day->update($request->only(['name', 'rest_day']));

            if ($request->has('exercises')) {
                $this->syncDayExercises($day, $request->input('exercises', []));
            }
        });

        $day->load(['exercises.exercise']);

        return response()->json(['day' => $this->planService->formatDayForResponse($day)]);
    }

    /**
     * DELETE /api/admin/workout-plans/{planId}/days/{dayId}
     */
    public function destroyDay(Request $request, int $planId, int $dayId): JsonResponse
    {
        $gymId = $request->user()->gym_id;

        $plan = WorkoutPlan::where('gym_id', $gymId)->find($planId);

        if (!$plan) {
            return response()->json(['message' => 'Plano não encontrado.'], 404);
        }

        $day = WorkoutPlanDay::where('plan_id', $planId)->find($dayId);

        if (!$day) {
            return response()->json(['message' => 'Dia não encontrado.'], 404);
        }

        $day->delete();

        return response()->json(['message' => 'Dia excluído com sucesso.']);
    }

    /**
     * POST /api/admin/users/{userId}/assign-plan
     */
    public function assignPlan(Request $request, int $userId): JsonResponse
    {
        $request->validate([
            'plan_id' => 'required|integer|exists:workout_plans,id',
        ]);

        $gymId = $request->user()->gym_id;

        $user = User::where('gym_id', $gymId)->find($userId);

        if (!$user) {
            return response()->json(['message' => 'Aluno não encontrado.'], 404);
        }

        $plan = WorkoutPlan::where('gym_id', $gymId)->find($request->plan_id);

        if (!$plan) {
            return response()->json(['message' => 'Plano não encontrado ou não pertence a esta academia.'], 404);
        }

        $userPlan = $this->planService->assignPlanToUser($userId, $request->plan_id, $gymId);

        return response()->json([
            'message'   => 'Plano atribuído com sucesso.',
            'user_plan' => [
                'user_id'           => $userPlan->user_id,
                'plan_id'           => $userPlan->plan_id,
                'plan_name'         => $plan->name,
                'current_day_index' => $userPlan->current_day_index,
                'started_at'        => $userPlan->started_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * POST /api/admin/workout-plans/{planId}/days/from-template
     * Body: { workout_id: int }
     * Copies all exercises from the given CustomWorkout template into a new day (snapshot — no coupling).
     */
    public function addDayFromTemplate(Request $request, int $planId): JsonResponse
    {
        $request->validate([
            'workout_id' => 'required|integer',
        ]);

        $gymId = $request->user()->gym_id;

        $plan = WorkoutPlan::where('gym_id', $gymId)->find($planId);

        if (!$plan) {
            return response()->json(['message' => 'Plano não encontrado.'], 404);
        }

        // Verify the template belongs to this gym (via user)
        $userIds = \App\Models\User::where('gym_id', $gymId)->pluck('id');
        $exists  = \App\Models\CustomWorkout::whereIn('user_id', $userIds)
            ->where('is_template', true)
            ->where('id', $request->workout_id)
            ->exists();

        if (!$exists) {
            return response()->json(['message' => 'Treino não encontrado.'], 404);
        }

        $day = $this->planService->addDayFromTemplate($plan, $request->workout_id);
        $day->load(['exercises.exercise']);

        return response()->json(['day' => $this->planService->formatDayForResponse($day)], 201);
    }

    /**
     * PATCH /api/admin/workout-plans/{planId}/days/reorder
     * Body: { days: [{id, day_order}] }
     */
    public function reorderDays(Request $request, int $planId): JsonResponse
    {
        $request->validate([
            'days'            => 'required|array|min:1',
            'days.*.id'       => 'required|integer',
            'days.*.day_order'=> 'required|integer|min:1',
        ]);

        $gymId = $request->user()->gym_id;

        $plan = WorkoutPlan::where('gym_id', $gymId)->find($planId);

        if (!$plan) {
            return response()->json(['message' => 'Plano não encontrado.'], 404);
        }

        $dayIds = collect($request->input('days'))->pluck('id');

        // Ensure all submitted IDs belong to this plan
        $validIds = WorkoutPlanDay::where('plan_id', $planId)->pluck('id');
        if ($dayIds->diff($validIds)->isNotEmpty()) {
            return response()->json(['message' => 'Um ou mais dias não pertencem a este plano.'], 422);
        }

        DB::transaction(function () use ($request, $planId) {
            foreach ($request->input('days') as $item) {
                WorkoutPlanDay::where('plan_id', $planId)
                    ->where('id', $item['id'])
                    ->update(['day_order' => $item['day_order']]);
            }
        });

        return response()->json(['message' => 'Ordem atualizada com sucesso.']);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private function syncDayExercises(WorkoutPlanDay $day, array $exercises): void
    {
        // Delete existing exercises for this day
        WorkoutExercise::where('plan_day_id', $day->id)->delete();

        foreach ($exercises as $index => $ex) {
            WorkoutExercise::create([
                'plan_day_id'      => $day->id,
                'exercise_id'      => $ex['exercise_id'],
                'sets'             => $ex['sets'] ?? null,
                'reps'             => isset($ex['reps']) ? (string) $ex['reps'] : null,
                'rest_seconds'     => $ex['rest_seconds'] ?? 60,
                'exercise_order'   => $ex['exercise_order'] ?? ($index + 1),
                'duration_minutes' => $ex['duration_minutes'] ?? null,
                'distance_km'      => isset($ex['distance_km']) ? (float) $ex['distance_km'] : null,
                'technique'        => $ex['technique'] ?? 'normal',
                'group_id'         => $ex['group_id'] ?? null,
                'rounds'           => $ex['rounds'] ?? null,
                'drops'            => $ex['drops'] ?? null,
            ]);
        }
    }
}
