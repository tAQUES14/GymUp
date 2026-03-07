<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ExerciseWeight;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProgressSummaryController extends Controller
{
    /**
     * GET /api/me/progress-summary
     *
     * Returns aggregated progress summary:
     * - Average e1RM change over 30 days
     * - Best improving exercise
     * - Latest PR (highest e1RM ever)
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        // Use Eloquent instead of raw SQL to avoid cast issues and SQL injection.
        // Get all exercise weights from the last 33 days for comparison windows.
        $recentDate = now()->subDays(33);

        $weights = ExerciseWeight::where('user_id', $userId)
            ->where('set_number', 1)
            ->where('created_at', '>=', $recentDate)
            ->get(['exercise_id', 'weight', 'reps', 'created_at']);

        $sevenDaysAgo    = now()->subDays(7);
        $pastWindowStart = now()->subDays(33);
        $pastWindowEnd   = now()->subDays(27);

        // Group by exercise and calculate current vs past e1RM
        $byExercise = $weights->groupBy('exercise_id');

        $totalDeltaPct     = 0.0;
        $totalDeltaAbs     = 0.0;
        $countWithProgress = 0;
        $bestExercise      = null;
        $bestDeltaPct      = null;

        // Get exercise names
        $exerciseIds = $byExercise->keys()->toArray();
        $exerciseNames = [];
        if (!empty($exerciseIds)) {
            $exerciseNames = DB::table('exercises')
                ->whereIn('id', $exerciseIds)
                ->pluck('name', 'id')
                ->toArray();
        }

        foreach ($byExercise as $exerciseId => $records) {
            // Current window: last 7 days
            $currentE1rm = $records
                ->filter(fn ($r) => $r->created_at->gte($sevenDaysAgo))
                ->map(fn ($r) => $r->weight * (1 + $r->reps / 30.0))
                ->max();

            // Past window: 27-33 days ago
            $pastE1rm = $records
                ->filter(fn ($r) =>
                    $r->created_at->gte($pastWindowStart) &&
                    $r->created_at->lte($pastWindowEnd)
                )
                ->map(fn ($r) => $r->weight * (1 + $r->reps / 30.0))
                ->max();

            if ($currentE1rm === null || $pastE1rm === null || $pastE1rm <= 0) {
                continue;
            }

            $deltaAbs = $currentE1rm - $pastE1rm;
            $deltaPct = ($deltaAbs / $pastE1rm) * 100;

            $totalDeltaPct += $deltaPct;
            $totalDeltaAbs += $deltaAbs;
            $countWithProgress++;

            if ($bestDeltaPct === null || $deltaPct > $bestDeltaPct) {
                $bestDeltaPct = $deltaPct;
                $bestExercise = [
                    'exercise_id' => $exerciseId,
                    'name'        => $exerciseNames[$exerciseId] ?? 'Exercício #' . $exerciseId,
                    'delta_pct'   => round($deltaPct, 1),
                ];
            }
        }

        // PR: best e1RM ever across all exercises
        $prRecord = ExerciseWeight::where('user_id', $userId)
            ->orderByRaw('(weight * (1 + reps / 30.0)) DESC')
            ->first(['exercise_id', 'weight', 'reps', 'created_at']);

        $latestPr = null;
        if ($prRecord) {
            $latestPr = [
                'exercise_id' => $prRecord->exercise_id,
                'name'        => $exerciseNames[$prRecord->exercise_id]
                    ?? 'Exercício #' . $prRecord->exercise_id,
                'weight'      => round((float) $prRecord->weight, 2),
                'reps'        => (int) $prRecord->reps,
            ];
        }

        return response()->json([
            'overall_delta_pct'       => $countWithProgress > 0
                ? round($totalDeltaPct / $countWithProgress, 1)
                : null,
            'overall_delta_abs'       => $countWithProgress > 0
                ? round($totalDeltaAbs / $countWithProgress, 1)
                : null,
            'best_exercise'           => $bestExercise,
            'latest_pr'               => $latestPr,
            'exercises_count'         => $byExercise->count(),
            'exercises_with_progress' => $countWithProgress,
        ]);
    }
}
