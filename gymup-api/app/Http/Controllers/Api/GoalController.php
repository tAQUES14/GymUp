<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BodyWeightLog;
use App\Models\UserGoal;
use App\Services\GoalService;
use Illuminate\Http\Request;

class GoalController extends Controller
{
    public function __construct(private GoalService $goalService) {}

    /**
     * POST /api/goals/preview
     *
     * Calculates estimates without persisting the goal.
     * Used by the mobile app to show a preview before the user confirms.
     */
    public function preview(Request $request)
    {
        $data = $request->validate($this->validationRules());

        return response()->json($this->goalService->previewGoal($data));
    }

    /**
     * POST /api/goals
     *
     * Creates (or replaces) the user's active goal.
     * Returns the calculated estimates in the response.
     */
    public function store(Request $request)
    {
        $data = $request->validate($this->validationRules());

        $goal = $this->goalService->createGoal($request->user(), $data);

        // Registra o peso inicial como peso corporal do dia,
        // para que a aba de metas reflita o peso atual corretamente.
        BodyWeightLog::updateOrCreate(
            ['user_id' => $request->user()->id, 'recorded_at' => now()->toDateString()],
            ['weight'  => $data['start_weight']]
        );

        return response()->json($this->formatGoal($goal), 201);
    }

    /**
     * GET /api/goals/current
     *
     * Returns the user's active goal or 404 if none exists.
     */
    public function current(Request $request)
    {
        $goal = UserGoal::where('user_id', $request->user()->id)
            ->latest()
            ->first();

        if (! $goal) {
            return response()->json(['message' => 'Nenhuma meta ativa.'], 404);
        }

        return response()->json($this->formatGoal($goal));
    }

    private function validationRules(): array
    {
        return [
            'goal_type'      => 'required|in:weight_loss,weight_gain,consistency',
            'gender'         => 'required|in:male,female',
            'start_weight'   => 'required|numeric|min:20|max:500',
            'target_weight'  => 'required|numeric|min:20|max:500',
            'height'         => 'required|numeric|min:100|max:250',
            'age'            => 'required|integer|min:10|max:120',
            'activity_level' => 'required|in:sedentary,light,moderate,intense',
            'target_months'  => 'required|integer|min:1|max:36',
        ];
    }

    private function formatGoal(UserGoal $goal): array
    {
        return [
            'goal_type'                       => $goal->goal_type,
            'gender'                          => $goal->gender,
            'start_weight'                    => (float) $goal->start_weight,
            'target_weight'                   => (float) $goal->target_weight,
            'height'                          => (float) $goal->height,
            'age'                             => (int) $goal->age,
            'activity_level'                  => $goal->activity_level,
            'target_months'                   => (int) $goal->target_months,
            'estimated_daily_calorie_deficit' => $goal->estimated_daily_calorie_deficit !== null
                ? (int) $goal->estimated_daily_calorie_deficit
                : null,
            'estimated_workouts_per_week'     => (int) $goal->estimated_workouts_per_week,
            'created_at'                      => $goal->created_at->toIso8601String(),
        ];
    }
}
