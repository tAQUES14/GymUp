<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProgressSummaryController extends Controller
{
    /**
     * GET /api/me/progress-summary
     *
     * Retorna resumo agregado de progresso do usuário:
     * - Evolução média 30 dias (delta_pct, delta_abs)
     * - Exercício que mais evoluiu
     * - PR mais recente (maior e1RM global)
     */
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        // Query 1: Para cada exercício, calcula e1RM atual (últimos 7d)
        // e e1RM passado (janela de 7d ao redor de 30 dias atrás).
        // Usa set_number = 1 como referência padrão.
        $exercises = DB::select("
            SELECT
                ew.exercise_id,
                e.name AS exercise_name,
                MAX(CASE
                    WHEN ew.created_at >= now() - interval '7 days'
                    THEN ew.weight * (1 + ew.reps / 30.0)
                END) AS current_e1rm,
                MAX(CASE
                    WHEN ew.created_at BETWEEN (now() - interval '33 days')
                                           AND (now() - interval '27 days')
                    THEN ew.weight * (1 + ew.reps / 30.0)
                END) AS past_e1rm
            FROM exercise_weights ew
            LEFT JOIN exercises e ON e.id = ew.exercise_id::integer
            WHERE ew.user_id = ?
              AND ew.set_number = 1
              AND ew.created_at >= now() - interval '33 days'
            GROUP BY ew.exercise_id, e.name
        ", [$userId]);

        $totalDeltaPct = 0.0;
        $totalDeltaAbs = 0.0;
        $countWithProgress = 0;
        $bestExercise = null;
        $bestDeltaPct = null;

        foreach ($exercises as $ex) {
            if ($ex->current_e1rm === null || $ex->past_e1rm === null || (float) $ex->past_e1rm <= 0) {
                continue;
            }

            $current = (float) $ex->current_e1rm;
            $past = (float) $ex->past_e1rm;
            $deltaAbs = $current - $past;
            $deltaPct = ($deltaAbs / $past) * 100;

            $totalDeltaPct += $deltaPct;
            $totalDeltaAbs += $deltaAbs;
            $countWithProgress++;

            if ($bestDeltaPct === null || $deltaPct > $bestDeltaPct) {
                $bestDeltaPct = $deltaPct;
                $bestExercise = [
                    'exercise_id' => $ex->exercise_id,
                    'name'        => $ex->exercise_name ?? 'Exercício #' . $ex->exercise_id,
                    'delta_pct'   => round($deltaPct, 1),
                ];
            }
        }

        // Query 2: PR global — registro com maior e1RM entre todos os exercícios
        $pr = DB::selectOne("
            SELECT
                ew.exercise_id,
                e.name AS exercise_name,
                ew.weight,
                ew.reps,
                ew.weight * (1 + ew.reps / 30.0) AS e1rm,
                ew.created_at
            FROM exercise_weights ew
            LEFT JOIN exercises e ON e.id = ew.exercise_id::integer
            WHERE ew.user_id = ?
            ORDER BY e1rm DESC, ew.created_at DESC
            LIMIT 1
        ", [$userId]);

        $latestPr = null;
        if ($pr && $pr->e1rm) {
            $latestPr = [
                'exercise_id' => $pr->exercise_id,
                'name'        => $pr->exercise_name ?? 'Exercício #' . $pr->exercise_id,
                'weight'      => round((float) $pr->weight, 2),
                'reps'        => (int) $pr->reps,
            ];
        }

        return response()->json([
            'overall_delta_pct'       => $countWithProgress > 0 ? round($totalDeltaPct / $countWithProgress, 1) : null,
            'overall_delta_abs'       => $countWithProgress > 0 ? round($totalDeltaAbs / $countWithProgress, 1) : null,
            'best_exercise'           => $bestExercise,
            'latest_pr'              => $latestPr,
            'exercises_count'         => count($exercises),
            'exercises_with_progress' => $countWithProgress,
        ]);
    }
}
