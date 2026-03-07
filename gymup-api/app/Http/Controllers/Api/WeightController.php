<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ExerciseWeight;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WeightController extends Controller
{
    /**
     * PUT /api/exercises/{exerciseId}/weight/set
     *
     * Cria um novo registro de carga para a série.
     * Sempre INSERT — nunca sobrescreve registros anteriores.
     */
    public function saveSetWeight(Request $request, $exerciseId)
    {
        $request->validate([
            'set_number' => 'required|integer|min:1',
            'weight'     => 'required|numeric|min:0|max:9999',
            'reps'       => 'nullable|integer|min:0|max:999',
        ]);

        $record = ExerciseWeight::create([
            'user_id'     => $request->user()->id,
            'gym_id'      => $request->user()->gym_id,
            'exercise_id' => (string) $exerciseId,
            'set_number'  => $request->set_number,
            'weight'      => $request->weight,
            'reps'        => $request->input('reps', 0),
        ]);

        return response()->json($record, 201);
    }

    /**
     * GET /api/exercises/{exerciseId}/weight/last
     *
     * Retorna o último peso registrado por set_number.
     * Response: { "1": 50.0, "2": 55.0, "3": 60.0 }
     */
    public function last(Request $request, $exerciseId)
    {
        $userId = $request->user()->id;

        // Subquery para pegar o maior id (mais recente) por set_number
        $latestIds = ExerciseWeight::where('user_id', $userId)
            ->where('exercise_id', (string) $exerciseId)
            ->selectRaw('MAX(id) as id')
            ->groupBy('set_number')
            ->pluck('id');

        if ($latestIds->isEmpty()) {
            return response()->json((object) []);
        }

        $records = ExerciseWeight::whereIn('id', $latestIds)
            ->orderBy('set_number')
            ->get(['set_number', 'weight']);

        $bySet = [];
        foreach ($records as $r) {
            $bySet[(string) $r->set_number] = (float) $r->weight;
        }

        return response()->json($bySet);
    }

    /**
     * GET /api/exercises/{exerciseId}/history
     *
     * Retorna histórico de cargas com filtros opcionais.
     */
    public function history(Request $request, $exerciseId)
    {
        $request->validate([
            'set_number' => 'nullable|integer|min:1',
            'limit'      => 'nullable|integer|min:1|max:200',
            'from'       => 'nullable|date_format:Y-m-d',
            'to'         => 'nullable|date_format:Y-m-d',
        ]);

        $limit = (int) $request->input('limit', 50);

        $query = ExerciseWeight::where('user_id', $request->user()->id)
            ->where('exercise_id', (string) $exerciseId);

        if ($request->filled('set_number')) {
            $query->where('set_number', (int) $request->set_number);
        }

        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->to);
        }

        $records = $query->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get(['set_number', 'weight', 'reps', 'created_at']);

        $result = $records->map(fn ($r) => [
            'set_number'  => $r->set_number,
            'weight'      => (float) $r->weight,
            'reps'        => (int) $r->reps,
            'created_at'  => $r->created_at->toIso8601String(),
        ]);

        return response()->json($result->values());
    }

    /**
     * GET /api/exercises/{exerciseId}/progress
     *
     * Agregação semanal do melhor e1RM por semana (PostgreSQL).
     */
    public function progress(Request $request, $exerciseId)
    {
        $request->validate([
            'set_number' => 'nullable|integer|min:1',
            'weeks'      => 'nullable|integer|min:1|max:52',
        ]);

        $userId    = $request->user()->id;
        $setNumber = $request->filled('set_number') ? (int) $request->set_number : null;
        $weeks     = (int) $request->input('weeks', 12);

        $fromDate = now()->subWeeks($weeks)->startOfWeek()->toDateString();

        if ($setNumber !== null) {
            $rows = DB::select("
                SELECT
                    date_trunc('week', created_at)::date AS week_start_date,
                    MAX(weight * (1 + reps / 30.0))      AS value
                FROM exercise_weights
                WHERE user_id = ?
                  AND exercise_id = ?
                  AND set_number = ?
                  AND created_at >= ?
                GROUP BY week_start_date
                ORDER BY week_start_date ASC
            ", [$userId, (string) $exerciseId, $setNumber, $fromDate]);
        } else {
            $rows = DB::select("
                SELECT
                    date_trunc('week', created_at)::date AS week_start_date,
                    MAX(weight * (1 + reps / 30.0))      AS value
                FROM exercise_weights
                WHERE user_id = ?
                  AND exercise_id = ?
                  AND created_at >= ?
                GROUP BY week_start_date
                ORDER BY week_start_date ASC
            ", [$userId, (string) $exerciseId, $fromDate]);
        }

        $result = array_map(fn ($r) => [
            'week_start_date' => $r->week_start_date,
            'value'           => round((float) $r->value, 2),
        ], $rows);

        return response()->json($result);
    }

    /**
     * GET /api/exercises/{exerciseId}/pr
     *
     * Personal Records do usuário para o exercício.
     */
    public function pr(Request $request, $exerciseId)
    {
        $userId = $request->user()->id;
        $exId   = (string) $exerciseId;

        $rows = DB::select("
            SELECT
                weight,
                reps,
                weight * (1 + reps / 30.0) AS e1rm,
                created_at
            FROM exercise_weights
            WHERE user_id = ?
              AND exercise_id = ?
            ORDER BY e1rm DESC, created_at DESC
            LIMIT 1
        ", [$userId, $exId]);

        if (empty($rows)) {
            return response()->json([
                'best_weight' => null,
                'best_reps'   => null,
                'best_e1rm'   => null,
                'created_at'  => null,
            ]);
        }

        $best = $rows[0];

        $bestWeight = DB::selectOne("
            SELECT MAX(weight) AS val FROM exercise_weights
            WHERE user_id = ? AND exercise_id = ?
        ", [$userId, $exId]);

        $bestReps = DB::selectOne("
            SELECT MAX(reps) AS val FROM exercise_weights
            WHERE user_id = ? AND exercise_id = ?
        ", [$userId, $exId]);

        return response()->json([
            'best_weight' => round((float) $bestWeight->val, 2),
            'best_reps'   => (int) $bestReps->val,
            'best_e1rm'   => round((float) $best->e1rm, 2),
            'created_at'  => $best->created_at,
        ]);
    }

    /**
     * GET /api/exercises/{exerciseId}/progress-score
     *
     * Compara e1RM atual vs passado.
     */
    public function progressScore(Request $request, $exerciseId)
    {
        $request->validate([
            'days'       => 'nullable|integer|min:7|max:365',
            'set_number' => 'nullable|integer|min:1',
        ]);

        $userId    = $request->user()->id;
        $exId      = (string) $exerciseId;
        $days      = (int) $request->input('days', 30);
        $setNumber = $request->filled('set_number') ? (int) $request->set_number : null;

        $currentDate = now()->subDays(7)->toDateTimeString();
        $pastStart   = now()->subDays($days + 3)->toDateTimeString();
        $pastEnd     = now()->subDays($days - 3)->toDateTimeString();

        if ($setNumber !== null) {
            $current = DB::selectOne("
                SELECT MAX(weight * (1 + reps / 30.0)) AS val
                FROM exercise_weights
                WHERE user_id = ?
                  AND exercise_id = ?
                  AND set_number = ?
                  AND created_at >= ?
            ", [$userId, $exId, $setNumber, $currentDate]);

            $past = DB::selectOne("
                SELECT MAX(weight * (1 + reps / 30.0)) AS val
                FROM exercise_weights
                WHERE user_id = ?
                  AND exercise_id = ?
                  AND set_number = ?
                  AND created_at BETWEEN ? AND ?
            ", [$userId, $exId, $setNumber, $pastStart, $pastEnd]);
        } else {
            $current = DB::selectOne("
                SELECT MAX(weight * (1 + reps / 30.0)) AS val
                FROM exercise_weights
                WHERE user_id = ?
                  AND exercise_id = ?
                  AND created_at >= ?
            ", [$userId, $exId, $currentDate]);

            $past = DB::selectOne("
                SELECT MAX(weight * (1 + reps / 30.0)) AS val
                FROM exercise_weights
                WHERE user_id = ?
                  AND exercise_id = ?
                  AND created_at BETWEEN ? AND ?
            ", [$userId, $exId, $pastStart, $pastEnd]);
        }

        $currentVal = $current->val ? round((float) $current->val, 2) : null;
        $pastVal    = $past->val    ? round((float) $past->val, 2)    : null;

        $deltaAbs = null;
        $deltaPct = null;

        if ($currentVal !== null && $pastVal !== null && $pastVal > 0) {
            $deltaAbs = round($currentVal - $pastVal, 2);
            $deltaPct = round(($deltaAbs / $pastVal) * 100, 1);
        }

        return response()->json([
            'current'   => $currentVal,
            'past'      => $pastVal,
            'delta_abs' => $deltaAbs,
            'delta_pct' => $deltaPct,
        ]);
    }
}
