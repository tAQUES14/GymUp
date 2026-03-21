<?php

namespace App\Services;

use App\Models\Exercise;
use App\Models\UserExerciseOverride;
use Illuminate\Support\Collection;

class ExerciseOverrideService
{
    /**
     * Build the merged exercise array for API responses.
     * Override fields take precedence over the base exercise fields.
     * Pass $pivot to include pivot data (sets/reps/rest) in the response.
     */
    public function resolveForApi(Exercise $exercise, ?UserExerciseOverride $override, array $pivot = []): array
    {
        $data = [
            'id'                => $exercise->id,
            'name'              => $exercise->name,
            'muscle_group'      => $exercise->muscle_group,
            'image_url'         => $exercise->image_url,
            'gif_url'           => $exercise->gif_url,
            'default_rest'      => $exercise->default_rest,
            'type'              => $exercise->type ?? 'strength',
            'primary_muscle'    => $exercise->primary_muscle,
            'secondary_muscles' => $exercise->secondary_muscles ?? [],
            'description'       => $override?->custom_description ?? $exercise->description,
            'video_url'         => $override?->custom_video_url ?? $exercise->video_url,
            'execution_steps'   => $override?->custom_execution_steps ?? $exercise->execution_steps ?? [],
            'common_mistakes'   => $exercise->common_mistakes ?? [],
            'tips'              => $override?->custom_tips ?? $exercise->tips ?? [],
            'has_override'      => $override !== null,
        ];

        if (!empty($pivot)) {
            $data['pivot'] = $pivot;
        }

        return $data;
    }

    /**
     * Batch-load all overrides for a user + list of exercise IDs.
     * Returns a Collection keyed by exercise_id.
     * One query — avoids N+1.
     */
    public function loadOverridesForUser(int $userId, array $exerciseIds): Collection
    {
        if (empty($exerciseIds)) {
            return collect();
        }

        return UserExerciseOverride::where('user_id', $userId)
            ->whereIn('exercise_id', $exerciseIds)
            ->get()
            ->keyBy('exercise_id');
    }

    /**
     * Create or update an override for a specific user + exercise.
     */
    public function upsert(int $exerciseId, int $userId, array $data): UserExerciseOverride
    {
        return UserExerciseOverride::updateOrCreate(
            ['exercise_id' => $exerciseId, 'user_id' => $userId],
            array_intersect_key($data, array_flip([
                'custom_video_url',
                'custom_description',
                'custom_execution_steps',
                'custom_tips',
            ]))
        );
    }

    /**
     * Delete an override if it exists. Returns true if something was deleted.
     */
    public function delete(int $exerciseId, int $userId): bool
    {
        return (bool) UserExerciseOverride::where('exercise_id', $exerciseId)
            ->where('user_id', $userId)
            ->delete();
    }
}
