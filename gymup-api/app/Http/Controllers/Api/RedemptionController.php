<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Reward;
use App\Models\Redemption;
use App\Services\PointService;
use Illuminate\Support\Facades\DB;

class RedemptionController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'reward_id' => 'required|integer|exists:rewards,id',
        ]);

        $user = $request->user();

        $reward = Reward::where('id', $request->reward_id)
            ->where('gym_id', $user->gym_id)
            ->where('active', true)
            ->first();

        if (!$reward) {
            return response()->json(['message' => 'Recompensa não encontrada.'], 404);
        }

        if ($reward->stock !== null && $reward->stock <= 0) {
            return response()->json(['message' => 'Sem estoque disponível.'], 400);
        }

        if ($user->points_balance < $reward->points_cost) {
            return response()->json(['message' => 'Pontos insuficientes.'], 422);
        }

        $alreadyPending = Redemption::where('user_id', $user->id)
            ->where('reward_id', $reward->id)
            ->where('status', 'pending')
            ->exists();

        if ($alreadyPending) {
            return response()->json([
                'message' => 'Você já possui uma solicitação pendente para esta recompensa.',
            ], 409);
        }

        Redemption::create([
            'user_id'      => $user->id,
            'reward_id'    => $reward->id,
            'gym_id'       => $user->gym_id,
            'points_spent' => $reward->points_cost,
            'status'       => 'pending',
        ]);

        return response()->json([
            'message' => 'Solicitação registrada com sucesso.',
        ], 201);
    }

    public function approve(Request $request, $id, PointService $pointService)
{
    $redemption = Redemption::with('reward', 'user')
        ->where('id', $id)
        ->where('status', 'pending')
        ->first();

    if (!$redemption) {
        return response()->json([
            'message' => 'Solicitação inválida ou já processada.'
        ], 404);
    }

    // 🔐 Proteção multi-academia
    if ($redemption->gym_id !== $request->user()->gym_id) {
        return response()->json([
            'message' => 'Acesso não autorizado para esta academia.'
        ], 403);
    }

    $reward = $redemption->reward;
    $user = $redemption->user;

    if ($reward->stock !== null && $reward->stock <= 0) {
        return response()->json([
            'message' => 'Sem estoque disponível.'
        ], 400);
    }

    $pointService->spendPoints(
        $user,
        $redemption->points_spent,
        'Resgate aprovado: ' . $reward->name
    );

    if ($reward->stock !== null) {
        $reward->decrement('stock');
    }

    $redemption->update([
        'status' => 'approved',
        'approved_at' => now()
    ]);

    return response()->json([
        'message' => 'Resgate aprovado com sucesso.'
    ]);
}

public function index(Request $request)
{
    $user = $request->user();

    // Só admin pode listar
    if ($user->role !== 'admin') {
        return response()->json(['message' => 'Acesso não autorizado.'], 403);
    }

    $query = Redemption::with(['user:id,name,email', 'reward:id,name,points_cost'])
        ->where('gym_id', $user->gym_id)
        ->orderByDesc('created_at');

    // Filtro opcional: ?status=pending|approved|rejected
    if ($request->filled('status')) {
        $status = $request->query('status');
        if (!in_array($status, ['pending', 'approved', 'rejected'])) {
            return response()->json(['message' => 'Status inválido.'], 422);
        }
        $query->where('status', $status);
    }

    // Paginação: ?per_page=10
    $perPage = (int) $request->query('per_page', 10);
    $perPage = max(1, min($perPage, 50));

    return response()->json(
        $query->paginate($perPage)
    );
}
}