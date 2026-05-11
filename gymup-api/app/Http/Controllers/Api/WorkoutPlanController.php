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
     * Retorna o treino do dia atual baseado no day_of_week do plano.
     * Se não houver plano atribuído → 404.
     * Se for dia de descanso → retorna rest_day=true com exercises=[].
     */
    public function today(Request $request): JsonResponse
    {
        $user = $request->user();
        $plan = $this->planService->getTodayPlanForUser($user);

        if (! $plan) {
            return response()->json([
                'message' => 'Nenhum plano de treino atribuído.',
            ], 404);
        }

        return response()->json($plan);
    }

    /**
     * GET /api/workout-plan/current
     *
     * Alias de today — mantido para compatibilidade de rota.
     */
    public function current(Request $request): JsonResponse
    {
        return $this->today($request);
    }
}
