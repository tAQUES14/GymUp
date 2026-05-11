<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ChallengeService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ChallengeController extends Controller
{
    public function __construct(private ChallengeService $challengeService) {}

    /**
     * GET /api/challenges/active
     *
     * Retorna o desafio comunitário ativo e todos os desafios pessoais ativos
     * com o progresso do aluno autenticado.
     */
    public function active(Request $request)
    {
        $user = $request->user();

        $community = $this->challengeService->getActiveCommunityChallenge($user->gym_id);

        $personalChallenges = $this->challengeService
            ->getActivePersonalChallenges($user->gym_id)
            ->map(fn ($c) => $this->challengeService->getChallengeData($c, $user))
            ->values()
            ->all();

        return response()->json([
            'challenge'          => $community
                ? $this->challengeService->getChallengeData($community, $user)
                : null,
            'personal_challenges' => $personalChallenges,
        ]);
    }

    /**
     * GET /api/challenges/{id}/ranking
     *
     * Retorna o ranking do desafio.
     * Para desafios competitivos, aceita ?week=YYYY-MM-DD para ver o ranking de uma semana.
     */
    public function ranking(Request $request, int $id)
    {
        $user      = $request->user();
        $challenge = \App\Models\GymChallenge::where('id', $id)
            ->where('gym_id', $user->gym_id)
            ->firstOrFail();

        if ($challenge->isCompetitive() && $request->has('week')) {
            $weekStart = Carbon::parse($request->input('week'))
                ->startOfWeek(Carbon::MONDAY)
                ->toDateString();

            return response()->json([
                'week_start' => $weekStart,
                'ranking'    => $this->challengeService->getWeeklyRanking($challenge, $weekStart),
            ]);
        }

        return response()->json([
            'challenge_id' => $challenge->id,
            'type'         => $challenge->type,
            'ranking'      => $this->challengeService->getRanking($challenge),
        ]);
    }
}
