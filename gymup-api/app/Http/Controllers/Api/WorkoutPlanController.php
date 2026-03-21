<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\WorkoutPlanService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WorkoutPlanController extends Controller
{
    public function __construct(private WorkoutPlanService $planService)
    {
    }

    /**
     * GET /api/workout-plan/today
     *
     * Returns the current day of the user's assigned workout plan.
     * 404 if no plan assigned.
     * If current day is a rest day, returns rest_day=true with empty exercises.
     */
    public function today(Request $request): JsonResponse
    {
        $user = $request->user();
        $plan = $this->planService->getCurrentPlanForUser($user);

        if (!$plan) {
            return response()->json([
                'message' => 'Nenhum plano de treino atribuído.',
            ], 404);
        }

        return response()->json($plan);
    }

    /**
     * GET /api/workout-plan/current
     *
     * Same as today — returns current day of the assigned plan with full info.
     */
    public function current(Request $request): JsonResponse
    {
        return $this->today($request);
    }
}
