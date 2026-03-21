<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WorkoutSession;
use App\Services\ExerciseProgressService;
use App\Services\WorkoutSetService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WorkoutSetController extends Controller
{
    public function __construct(
        private WorkoutSetService       $service,
        private ExerciseProgressService $progressService,
    ) {}

    /**
     * GET /api/exercises/{exerciseId}/last-sets
     *
     * Returns the enriched last-sets snapshot:
     * sets, max_weight, volume, estimated_1rm, workout_date.
     */
    public function lastSets(Request $request, int $exerciseId): JsonResponse
    {
        $data = $this->progressService->getLastSets($exerciseId, $request->user()->id);

        if ($data === null) {
            return response()->json([
                'exercise_id'   => $exerciseId,
                'workout_date'  => null,
                'sets'          => [],
                'max_weight'    => null,
                'volume'        => null,
                'estimated_1rm' => null,
            ]);
        }

        return response()->json($data);
    }

    /**
     * GET /api/exercises/{exerciseId}/workout-history
     *
     * Returns last 20 finished sessions containing this exercise,
     * ordered chronologically, with per-session metrics.
     */
    public function workoutHistory(Request $request, int $exerciseId): JsonResponse
    {
        $history = $this->progressService->getExerciseHistory(
            $request->user()->id,
            $exerciseId
        );

        return response()->json([
            'exercise_id' => $exerciseId,
            'history'     => $history,
        ]);
    }

    /**
     * GET /api/exercises/prs
     *
     * Returns all-time PRs across every exercise the authenticated user
     * has ever trained (max weight + max estimated 1RM).
     */
    public function allPRs(Request $request): JsonResponse
    {
        $prs = $this->progressService->getAllUserPRs($request->user()->id);

        return response()->json(['prs' => $prs]);
    }

    /**
     * POST /api/workout-sets
     *
     * Saves all sets for one exercise within a workout session.
     * Idempotent: replaces previously saved sets for the same exercise+session.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'workout_session_id'       => 'required|integer|exists:workout_sessions,id',
            'exercise_id'              => 'required|integer|exists:exercises,id',
            'sets'                     => 'required|array|min:1',
            'sets.*.set_number'        => 'required|integer|min:1',
            'sets.*.weight'            => 'required|numeric|min:0',
            'sets.*.reps'              => 'required|integer|min:0',
        ]);

        $user    = $request->user();
        $session = WorkoutSession::where('id', $request->workout_session_id)
            ->where('user_id', $user->id)
            ->first();

        if (!$session) {
            return response()->json(['message' => 'Sessão não encontrada.'], 404);
        }

        $this->service->saveSets(
            $request->workout_session_id,
            $request->exercise_id,
            $request->sets
        );

        return response()->json(['message' => 'Sets salvos com sucesso.']);
    }
}
