<?php

namespace App\Services;

use App\Models\Exercise;
use App\Models\WorkoutSet;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class ExerciseProgressService
{
    // ── Core math helpers ─────────────────────────────────────────────────────

    /** Volume = sum(weight × reps) across all sets. */
    public function calculateVolume(Collection $sets): float
    {
        return (float) $sets->sum(fn ($s) => (float) $s->weight * (int) $s->reps);
    }

    /**
     * Epley formula: 1RM ≈ weight × (1 + reps / 30).
     * Only reliable for 1–12 reps; returns 0 outside that range.
     */
    public function calculateEstimated1RM(float $weight, int $reps): float
    {
        if ($reps <= 0 || $reps > 12 || $weight <= 0) {
            return 0.0;
        }

        return round($weight * (1 + $reps / 30.0), 1);
    }

    // ── Feature 1 — enriched last-sets ────────────────────────────────────────

    /**
     * Returns the sets from the user's most recent finished session for this
     * exercise, enriched with aggregated metrics.
     * Returns null when no history exists.
     */
    public function getLastSets(int $exerciseId, int $userId): ?array
    {
        $row = DB::table('workout_sets')
            ->join('workout_sessions', 'workout_sets.workout_session_id', '=', 'workout_sessions.id')
            ->where('workout_sessions.user_id', $userId)
            ->whereNotNull('workout_sessions.finished_at')
            ->where('workout_sets.exercise_id', $exerciseId)
            ->orderByDesc('workout_sessions.finished_at')
            ->select('workout_sets.workout_session_id', 'workout_sessions.finished_at')
            ->first();

        if (!$row) {
            return null;
        }

        $sets = WorkoutSet::where('workout_session_id', $row->workout_session_id)
            ->where('exercise_id', $exerciseId)
            ->orderBy('set_number')
            ->get();

        if ($sets->isEmpty()) {
            return null;
        }

        $maxWeight   = (float) $sets->max('weight');
        $volume      = $this->calculateVolume($sets);
        $estimated1RM = (float) $sets->max(
            fn ($s) => $this->calculateEstimated1RM((float) $s->weight, (int) $s->reps)
        );

        return [
            'exercise_id'   => $exerciseId,
            'workout_date'  => substr((string) $row->finished_at, 0, 10),
            'sets'          => $sets->map(fn ($s) => [
                'set'    => $s->set_number,
                'weight' => (float) $s->weight,
                'reps'   => (int) $s->reps,
            ])->values()->all(),
            'max_weight'    => $maxWeight,
            'volume'        => $volume,
            'estimated_1rm' => $estimated1RM,
        ];
    }

    // ── Feature 2 — exercise history ──────────────────────────────────────────

    /**
     * Returns the last 20 sessions containing this exercise, ordered
     * chronologically (ascending) with per-session metrics.
     * Avoids N+1 by loading all sets in two queries.
     */
    public function getExerciseHistory(int $userId, int $exerciseId): array
    {
        // Step 1: find distinct session IDs (with their finish dates) — one query
        $sessionRows = DB::table('workout_sets')
            ->join('workout_sessions', 'workout_sets.workout_session_id', '=', 'workout_sessions.id')
            ->where('workout_sessions.user_id', $userId)
            ->whereNotNull('workout_sessions.finished_at')
            ->where('workout_sets.exercise_id', $exerciseId)
            ->orderByDesc('workout_sessions.finished_at')
            ->select('workout_sets.workout_session_id', 'workout_sessions.finished_at')
            ->distinct()
            ->limit(20)
            ->get();

        if ($sessionRows->isEmpty()) {
            return [];
        }

        $sessionIds  = $sessionRows->pluck('workout_session_id');
        $sessionDates = $sessionRows->pluck('finished_at', 'workout_session_id');

        // Step 2: load all sets for those sessions — one query
        $allSets = WorkoutSet::whereIn('workout_session_id', $sessionIds)
            ->where('exercise_id', $exerciseId)
            ->get()
            ->groupBy('workout_session_id');

        // Step 3: build history array, then sort chronologically for chart display
        $history = $sessionIds->map(function ($sessionId) use ($allSets, $sessionDates) {
            $sets = $allSets->get($sessionId);
            if (!$sets || $sets->isEmpty()) {
                return null;
            }

            return [
                'date'          => substr((string) ($sessionDates[$sessionId] ?? ''), 0, 10),
                'max_weight'    => (float) $sets->max('weight'),
                'volume'        => $this->calculateVolume($sets),
                'estimated_1rm' => (float) $sets->max(
                    fn ($s) => $this->calculateEstimated1RM((float) $s->weight, (int) $s->reps)
                ),
            ];
        })->filter()->values()->sortBy('date')->values()->all();

        return $history;
    }

    // ── Feature 3 — personal records ──────────────────────────────────────────

    /**
     * Returns all-time PRs for a specific exercise for the given user.
     */
    public function getExercisePRs(int $userId, int $exerciseId): array
    {
        $sets = DB::table('workout_sets')
            ->join('workout_sessions', 'workout_sets.workout_session_id', '=', 'workout_sessions.id')
            ->where('workout_sessions.user_id', $userId)
            ->whereNotNull('workout_sessions.finished_at')
            ->where('workout_sets.exercise_id', $exerciseId)
            ->select('workout_sets.weight', 'workout_sets.reps', 'workout_sessions.id as session_id')
            ->get();

        if ($sets->isEmpty()) {
            return [];
        }

        $maxWeight  = (float) $sets->max('weight');
        $max1RM     = (float) $sets->max(
            fn ($s) => $this->calculateEstimated1RM((float) $s->weight, (int) $s->reps)
        );

        // Max volume is per-session, so group first
        $maxVolume  = (float) $sets->groupBy('session_id')->map(
            fn ($g) => $g->sum(fn ($s) => (float) $s->weight * (int) $s->reps)
        )->max();

        return [
            'max_weight'        => $maxWeight,
            'max_volume'        => $maxVolume,
            'max_estimated_1rm' => $max1RM,
        ];
    }

    /**
     * Detects if the current session set any new all-time PR for each exercise.
     * Returns an array of human-readable PR message strings (one per exercise).
     * Uses two queries per exercise to avoid loading all historical data into memory.
     */
    public function detectPRs(int $userId, int $currentSessionId): array
    {
        $exerciseIds = WorkoutSet::where('workout_session_id', $currentSessionId)
            ->pluck('exercise_id')
            ->unique();

        if ($exerciseIds->isEmpty()) {
            return [];
        }

        $messages = [];

        foreach ($exerciseIds as $exerciseId) {
            $currentSets = WorkoutSet::where('workout_session_id', $currentSessionId)
                ->where('exercise_id', $exerciseId)
                ->get();

            // All-time historical bests (excluding current session) — single query per exercise
            $historical = DB::table('workout_sets')
                ->join('workout_sessions', 'workout_sets.workout_session_id', '=', 'workout_sessions.id')
                ->where('workout_sessions.user_id', $userId)
                ->whereNotNull('workout_sessions.finished_at')
                ->where('workout_sets.exercise_id', $exerciseId)
                ->where('workout_sessions.id', '!=', $currentSessionId)
                ->selectRaw('
                    MAX(workout_sets.weight) as max_weight,
                    MAX(CASE WHEN workout_sets.reps BETWEEN 1 AND 12
                        THEN workout_sets.weight * (1 + workout_sets.reps / 30.0)
                        ELSE 0 END) as max_1rm,
                    workout_sets.workout_session_id
                ')
                ->groupBy('workout_sets.workout_session_id')
                ->get();

            if ($historical->isEmpty()) {
                continue;
            }

            $prevMaxWeight = (float) $historical->max('max_weight');
            $prevMax1RM    = (float) $historical->max('max_1rm');
            $prevMaxVolume = (float) DB::table('workout_sets')
                ->join('workout_sessions', 'workout_sets.workout_session_id', '=', 'workout_sessions.id')
                ->where('workout_sessions.user_id', $userId)
                ->whereNotNull('workout_sessions.finished_at')
                ->where('workout_sets.exercise_id', $exerciseId)
                ->where('workout_sessions.id', '!=', $currentSessionId)
                ->selectRaw('SUM(workout_sets.weight * workout_sets.reps) as vol')
                ->groupBy('workout_sets.workout_session_id')
                ->orderByDesc('vol')
                ->limit(1)
                ->value('vol') ?? 0;

            $currMaxWeight = (float) $currentSets->max('weight');
            $currMax1RM    = (float) $currentSets->max(
                fn ($s) => $this->calculateEstimated1RM((float) $s->weight, (int) $s->reps)
            );
            $currVolume    = $this->calculateVolume($currentSets);

            $name = Exercise::select('name')->find($exerciseId)?->name ?? 'exercício';

            if ($currMaxWeight > $prevMaxWeight) {
                $kg = number_format($currMaxWeight, $currMaxWeight == floor($currMaxWeight) ? 0 : 1);
                $messages[] = "🔥 Novo recorde de carga: {$kg}kg no {$name}";
            } elseif ($currMax1RM > $prevMax1RM) {
                $rm = number_format($currMax1RM, 1);
                $messages[] = "🔥 Novo 1RM estimado: {$rm}kg no {$name}";
            } elseif ($currVolume > $prevMaxVolume && $prevMaxVolume > 0) {
                $messages[] = "🔥 Novo recorde de volume no {$name}";
            }
        }

        return $messages;
    }

    // ── PR Board — all-time bests across every exercise ───────────────────────

    /**
     * Returns all-time PRs for every exercise the user has ever trained,
     * grouped by muscle group. Uses all historical data (no 20-session cap).
     */
    public function getAllUserPRs(int $userId): array
    {
        $rows = DB::table('workout_sets')
            ->join('workout_sessions', 'workout_sets.workout_session_id', '=', 'workout_sessions.id')
            ->join('exercises', 'workout_sets.exercise_id', '=', 'exercises.id')
            ->where('workout_sessions.user_id', $userId)
            ->whereNotNull('workout_sessions.finished_at')
            ->groupBy('workout_sets.exercise_id', 'exercises.name', 'exercises.muscle_group')
            ->selectRaw("
                workout_sets.exercise_id,
                exercises.name,
                exercises.muscle_group,
                MAX(workout_sets.weight) AS max_weight,
                MAX(CASE WHEN workout_sets.reps BETWEEN 1 AND 12
                    THEN workout_sets.weight * (1 + workout_sets.reps / 30.0)
                    ELSE 0 END) AS max_estimated_1rm
            ")
            ->orderBy('exercises.name')
            ->get();

        return $rows->map(fn ($r) => [
            'exercise_id'       => (int) $r->exercise_id,
            'exercise_name'     => $r->name,
            'muscle_group'      => $r->muscle_group ?? '',
            'max_weight'        => (float) $r->max_weight,
            'max_estimated_1rm' => $r->max_estimated_1rm > 0
                ? round((float) $r->max_estimated_1rm, 1)
                : null,
        ])->all();
    }

    // ── Feature 10 — workout volume ───────────────────────────────────────────

    /** Total volume (weight × reps) across all sets in a session. */
    public function getSessionVolume(int $sessionId): float
    {
        return (float) DB::table('workout_sets')
            ->where('workout_session_id', $sessionId)
            ->selectRaw('SUM(weight * reps) as total')
            ->value('total') ?? 0.0;
    }
}
