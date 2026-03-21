<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exercise;
use App\Models\User;
use App\Models\UserExerciseOverride;
use App\Services\ExerciseOverrideService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminExerciseOverrideController extends Controller
{
    public function __construct(private ExerciseOverrideService $overrideService)
    {
    }

    /**
     * GET /api/admin/users/{userId}/exercise-overrides
     *
     * List all overrides for a student, each merged with its base exercise.
     */
    public function index(int $userId): JsonResponse
    {
        $overrides = UserExerciseOverride::where('user_id', $userId)
            ->with('exercise')
            ->get()
            ->map(fn ($o) => [
                'exercise_id'            => $o->exercise_id,
                'exercise_name'          => $o->exercise?->name,
                'muscle_group'           => $o->exercise?->muscle_group,
                'custom_video_url'       => $o->custom_video_url,
                'custom_description'     => $o->custom_description,
                'custom_execution_steps' => $o->custom_execution_steps,
                'custom_tips'            => $o->custom_tips,
                'updated_at'             => $o->updated_at?->toIso8601String(),
            ]);

        return response()->json(['overrides' => $overrides]);
    }

    /**
     * GET /api/admin/users/{userId}/exercises/{exerciseId}/override
     *
     * Returns the base exercise + current override for trainer context.
     */
    public function show(int $userId, int $exerciseId): JsonResponse
    {
        $exercise = Exercise::findOrFail($exerciseId);
        $override = UserExerciseOverride::where('exercise_id', $exerciseId)
            ->where('user_id', $userId)
            ->first();

        return response()->json([
            'base_exercise' => [
                'id'              => $exercise->id,
                'name'            => $exercise->name,
                'muscle_group'    => $exercise->muscle_group,
                'video_url'       => $exercise->video_url,
                'description'     => $exercise->description,
                'execution_steps' => $exercise->execution_steps ?? [],
                'tips'            => $exercise->tips ?? [],
            ],
            'override'       => $override,
            'resolved'       => $this->overrideService->resolveForApi($exercise, $override),
        ]);
    }

    /**
     * PUT /api/admin/users/{userId}/exercises/{exerciseId}/override
     *
     * Upsert an override. Send null to clear a specific field.
     */
    public function upsert(Request $request, int $userId, int $exerciseId): JsonResponse
    {
        // Verify exercise and user exist in the same gym
        $exercise = Exercise::findOrFail($exerciseId);
        $student  = User::findOrFail($userId);

        $request->validate([
            'custom_video_url'         => 'nullable|string|max:500',
            'custom_description'       => 'nullable|string',
            'custom_execution_steps'   => 'nullable|array',
            'custom_execution_steps.*' => 'string',
            'custom_tips'              => 'nullable|array',
            'custom_tips.*'            => 'string',
        ]);

        $override = $this->overrideService->upsert($exerciseId, $userId, $request->only([
            'custom_video_url',
            'custom_description',
            'custom_execution_steps',
            'custom_tips',
        ]));

        return response()->json([
            'message'  => 'Personalização salva.',
            'override' => $override,
            'resolved' => $this->overrideService->resolveForApi($exercise, $override),
        ]);
    }

    /**
     * DELETE /api/admin/users/{userId}/exercises/{exerciseId}/override
     *
     * Remove all overrides for this exercise+user — reverts to global defaults.
     */
    public function destroy(int $userId, int $exerciseId): JsonResponse
    {
        $this->overrideService->delete($exerciseId, $userId);

        return response()->json(['message' => 'Personalização removida. Usando conteúdo padrão.']);
    }
}
