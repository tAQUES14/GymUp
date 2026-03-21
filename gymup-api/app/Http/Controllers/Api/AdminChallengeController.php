<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GymChallenge;
use App\Services\ChallengeService;
use Illuminate\Http\Request;

class AdminChallengeController extends Controller
{
    public function __construct(private ChallengeService $challengeService) {}

    /**
     * GET /api/admin/challenges
     *
     * Lista todos os desafios da academia.
     */
    public function index(Request $request)
    {
        $challenges = GymChallenge::where('gym_id', $request->user()->gym_id)
            ->withCount('participants')
            ->orderByDesc('starts_at')
            ->get();

        return response()->json(['challenges' => $challenges]);
    }

    /**
     * GET /api/admin/challenges/{id}
     *
     * Retorna detalhes de um desafio com participantes.
     */
    public function show(Request $request, int $id)
    {
        $challenge = GymChallenge::where('id', $id)
            ->where('gym_id', $request->user()->gym_id)
            ->withCount('participants')
            ->firstOrFail();

        $participants = $challenge->participants()
            ->with('user:id,name,email')
            ->orderByDesc('total_challenge_points')
            ->orderByDesc('workouts_this_challenge')
            ->get()
            ->map(fn($p) => [
                'id'                     => $p->id,
                'user_id'                => $p->user_id,
                'name'                   => $p->user->name ?? '—',
                'email'                  => $p->user->email ?? '—',
                'total_challenge_points' => $p->total_challenge_points,
                'workouts_this_challenge'=> $p->workouts_this_challenge,
                'goal_completed'         => $p->goal_completed,
                'goal_completed_at'      => $p->goal_completed_at?->toDateString(),
                'reward_granted'         => $p->reward_granted,
            ]);

        return response()->json([
            'challenge'    => $challenge,
            'participants' => $participants,
        ]);
    }

    /**
     * DELETE /api/admin/challenges/{id}
     *
     * Remove um desafio (somente se ainda não iniciado).
     */
    public function destroy(Request $request, int $id)
    {
        $challenge = GymChallenge::where('id', $id)
            ->where('gym_id', $request->user()->gym_id)
            ->firstOrFail();

        if ($challenge->starts_at->isPast()) {
            return response()->json([
                'message' => 'Não é possível excluir um desafio que já foi iniciado.',
            ], 422);
        }

        $challenge->delete();

        return response()->json(['message' => 'Desafio excluído com sucesso.']);
    }

    /**
     * POST /api/admin/challenges
     *
     * Cria um novo desafio.
     * Regra: não pode haver outro desafio ativo no mesmo período.
     */
    public function store(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'type'        => 'required|in:competitive,simple',
            'name'        => 'required|string|max:255',
            'description' => 'nullable|string',
            'starts_at'   => 'required|date|after_or_equal:today',
            'ends_at'     => 'required|date|after:starts_at',

            // Recompensa
            'reward_type'        => 'nullable|in:points,physical,none',
            'reward_description' => 'nullable|string',

            // Competitivo
            'min_weekly_workouts'    => 'required_if:type,competitive|nullable|integer|min:1|max:7',
            'max_weekly_workouts'    => 'required_if:type,competitive|nullable|integer|min:1|max:7',
            'weekly_points_config'   => 'required_if:type,competitive|nullable|array',
            'weekly_points_config.*' => 'integer|min:0',

            // Simples
            'goal_workouts' => 'required_if:type,simple|nullable|integer|min:1',
            'reward_points' => 'nullable|integer|min:0',
        ]);

        // Valida regra: apenas um desafio ativo por vez
        $conflict = GymChallenge::where('gym_id', $user->gym_id)
            ->where('status', 'active')
            ->where('starts_at', '<=', $data['ends_at'])
            ->where('ends_at', '>=', $data['starts_at'])
            ->exists();

        if ($conflict) {
            return response()->json([
                'message' => 'Já existe um desafio ativo nesse período. Finalize-o antes de criar um novo.',
            ], 422);
        }

        $challenge = GymChallenge::create(array_merge($data, [
            'gym_id'      => $user->gym_id,
            'status'      => 'active',
            'reward_type' => $data['reward_type'] ?? 'points',
        ]));

        return response()->json(['challenge' => $challenge], 201);
    }

    /**
     * PUT /api/admin/challenges/{id}
     *
     * Atualiza um desafio. Só é permitido antes de iniciar (starts_at > hoje).
     */
    public function update(Request $request, int $id)
    {
        $challenge = GymChallenge::where('id', $id)
            ->where('gym_id', $request->user()->gym_id)
            ->firstOrFail();

        if ($challenge->starts_at->isPast()) {
            return response()->json([
                'message' => 'Não é possível editar um desafio que já foi iniciado.',
            ], 422);
        }

        $data = $request->validate([
            'name'                   => 'sometimes|string|max:255',
            'description'            => 'sometimes|nullable|string',
            'starts_at'              => 'sometimes|date',
            'ends_at'                => 'sometimes|date|after:starts_at',
            'reward_type'            => 'sometimes|in:points,physical,none',
            'reward_description'     => 'sometimes|nullable|string',
            'min_weekly_workouts'    => 'sometimes|nullable|integer|min:1|max:7',
            'max_weekly_workouts'    => 'sometimes|nullable|integer|min:1|max:7',
            'weekly_points_config'   => 'sometimes|nullable|array',
            'weekly_points_config.*' => 'integer|min:0',
            'goal_workouts'          => 'sometimes|nullable|integer|min:1',
            'reward_points'          => 'sometimes|nullable|integer|min:0',
        ]);

        $challenge->update($data);

        return response()->json(['challenge' => $challenge->fresh()]);
    }

    /**
     * POST /api/admin/challenges/{id}/finish
     *
     * Encerra manualmente um desafio ativo.
     */
    public function finish(Request $request, int $id)
    {
        $challenge = GymChallenge::where('id', $id)
            ->where('gym_id', $request->user()->gym_id)
            ->where('status', 'active')
            ->firstOrFail();

        // Finaliza semanas pendentes antes de encerrar
        $this->challengeService->finalizeCompletedWeeks($challenge);

        $challenge->update(['status' => 'finished']);

        return response()->json([
            'message'   => 'Desafio encerrado com sucesso.',
            'challenge' => $challenge->fresh(),
        ]);
    }
}
