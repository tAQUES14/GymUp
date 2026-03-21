<?php

namespace App\Services;

use App\Models\Exercise;
use App\Models\WorkoutSet;
use Illuminate\Support\Facades\DB;

class WorkoutSetService
{
    /**
     * Save (upsert) all sets for a given exercise within a session.
     * Replaces any previously saved sets for the same exercise in this session.
     */
    public function saveSets(int $sessionId, int $exerciseId, array $sets): void
    {
        DB::transaction(function () use ($sessionId, $exerciseId, $sets) {
            WorkoutSet::where('workout_session_id', $sessionId)
                ->where('exercise_id', $exerciseId)
                ->delete();

            foreach ($sets as $set) {
                WorkoutSet::create([
                    'workout_session_id' => $sessionId,
                    'exercise_id'        => $exerciseId,
                    'set_number'         => (int) $set['set_number'],
                    'weight'             => (float) $set['weight'],
                    'reps'               => (int) $set['reps'],
                ]);
            }
        });
    }

    /**
     * Return the sets from the user's most recent finished session
     * that included this exercise. Returns [] if no history exists.
     */
    public function getLastSets(int $exerciseId, int $userId): array
    {
        $sessionId = DB::table('workout_sets')
            ->join('workout_sessions', 'workout_sets.workout_session_id', '=', 'workout_sessions.id')
            ->where('workout_sessions.user_id', $userId)
            ->whereNotNull('workout_sessions.finished_at')
            ->where('workout_sets.exercise_id', $exerciseId)
            ->orderByDesc('workout_sessions.finished_at')
            ->value('workout_sets.workout_session_id');

        if (!$sessionId) {
            return [];
        }

        return WorkoutSet::where('workout_session_id', $sessionId)
            ->where('exercise_id', $exerciseId)
            ->orderBy('set_number')
            ->get()
            ->map(fn ($s) => [
                'set_number' => $s->set_number,
                'weight'     => (float) $s->weight,
                'reps'       => (int) $s->reps,
            ])
            ->all();
    }

    /**
     * Compare the current session's sets against the previous session for each
     * exercise. Returns a motivational progress message for the biggest improvement,
     * or null if nothing improved.
     */
    public function detectProgress(int $userId, int $currentSessionId): ?string
    {
        $exerciseIds = WorkoutSet::where('workout_session_id', $currentSessionId)
            ->pluck('exercise_id')
            ->unique();

        if ($exerciseIds->isEmpty()) {
            return null;
        }

        $bestMessage = null;
        $bestScore   = 0.0;

        foreach ($exerciseIds as $exerciseId) {
            $currentSets = WorkoutSet::where('workout_session_id', $currentSessionId)
                ->where('exercise_id', $exerciseId)
                ->get();

            // Find previous session (not the current one) that recorded sets for this exercise
            $prevSessionId = DB::table('workout_sets')
                ->join('workout_sessions', 'workout_sets.workout_session_id', '=', 'workout_sessions.id')
                ->where('workout_sessions.user_id', $userId)
                ->whereNotNull('workout_sessions.finished_at')
                ->where('workout_sets.exercise_id', $exerciseId)
                ->where('workout_sessions.id', '!=', $currentSessionId)
                ->orderByDesc('workout_sessions.finished_at')
                ->value('workout_sets.workout_session_id');

            if (!$prevSessionId) {
                continue;
            }

            $prevSets = WorkoutSet::where('workout_session_id', $prevSessionId)
                ->where('exercise_id', $exerciseId)
                ->get();

            $currMaxWeight  = (float) $currentSets->max('weight');
            $prevMaxWeight  = (float) $prevSets->max('weight');
            $currVolume     = (float) $currentSets->sum(fn ($s) => $s->weight * $s->reps);
            $prevVolume     = (float) $prevSets->sum(fn ($s) => $s->weight * $s->reps);
            $currTotalReps  = (int) $currentSets->sum('reps');
            $prevTotalReps  = (int) $prevSets->sum('reps');

            $weightDiff = $currMaxWeight - $prevMaxWeight;
            $repsDiff   = $currTotalReps - $prevTotalReps;
            $volumeDiff = $currVolume - $prevVolume;

            // Score: weight gain is most meaningful, then reps, then volume
            $score = max(
                $weightDiff * 5,
                $repsDiff * 2,
                $prevVolume > 0 ? ($volumeDiff / $prevVolume) * 50 : 0
            );

            if ($score > $bestScore) {
                $name = Exercise::select('name')->find($exerciseId)?->name ?? 'exercício';

                if ($weightDiff > 0) {
                    $kg = number_format($weightDiff, $weightDiff == floor($weightDiff) ? 0 : 1);
                    $bestMessage = "+{$kg}kg no {$name} desde o último treino";
                } elseif ($repsDiff > 0) {
                    $bestMessage = "+{$repsDiff} rep no {$name} desde o último treino";
                } elseif ($volumeDiff > 0) {
                    $vol = number_format($volumeDiff, 0);
                    $bestMessage = "+{$vol}kg de volume no {$name}";
                }

                $bestScore = $score;
            }
        }

        return $bestMessage;
    }
}
