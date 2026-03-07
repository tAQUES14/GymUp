<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BodyWeightLog;
use Illuminate\Http\Request;

class BodyWeightController extends Controller
{
    /**
     * POST /api/body-weight
     *
     * Registra ou atualiza o peso corporal do dia.
     * Se já existe um registro para hoje, substitui (upsert por data).
     */
    public function store(Request $request)
    {
        $request->validate([
            'weight' => 'required|numeric|min:20|max:500',
        ]);

        $today = now()->toDateString();

        $log = BodyWeightLog::updateOrCreate(
            ['user_id' => $request->user()->id, 'recorded_at' => $today],
            ['weight' => $request->weight]
        );

        return response()->json([
            'weight'      => (float) $log->weight,
            'recorded_at' => $log->recorded_at->toDateString(),
        ], $log->wasRecentlyCreated ? 201 : 200);
    }

    /**
     * GET /api/body-weight
     *
     * Retorna o histórico de pesos do usuário (mais recente primeiro).
     * Opcional: ?limit=N (default 30).
     */
    public function index(Request $request)
    {
        $request->validate([
            'limit' => 'nullable|integer|min:1|max:365',
        ]);

        $limit = (int) $request->input('limit', 30);

        $logs = BodyWeightLog::where('user_id', $request->user()->id)
            ->orderBy('recorded_at', 'desc')
            ->limit($limit)
            ->get(['weight', 'recorded_at']);

        return response()->json(
            $logs->map(fn ($l) => [
                'weight'      => (float) $l->weight,
                'recorded_at' => $l->recorded_at->toDateString(),
            ])->values()
        );
    }
}
