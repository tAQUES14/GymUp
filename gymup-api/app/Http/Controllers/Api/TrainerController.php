<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TrainerController extends Controller
{
    /**
     * GET /api/trainer/gyms
     *
     * Lista as filiais às quais o trainer autenticado está vinculado
     * via trainer_gyms, indicando qual é a is_primary e qual está ativa.
     */
    public function gyms(Request $request): JsonResponse
    {
        $trainer = $request->user();

        $gyms = $trainer->gyms()
            ->get()
            ->map(fn (Gym $gym) => [
                'id'         => $gym->id,
                'name'       => $gym->name,
                'is_primary' => (bool) $gym->pivot->is_primary,
                'is_active'  => $gym->id === $trainer->activeGymId(),
            ]);

        return response()->json(['gyms' => $gyms]);
    }

    /**
     * POST /api/trainer/switch-gym
     *
     * Troca a filial ativa do trainer.
     * Valida que o trainer possui vínculo em trainer_gyms antes de atualizar.
     */
    public function switchGym(Request $request): JsonResponse
    {
        $request->validate(['gym_id' => 'required|integer|min:1']);

        $trainer = $request->user();
        $gymId   = (int) $request->input('gym_id');

        $linked = $trainer->gyms()->where('gyms.id', $gymId)->exists();

        if (! $linked) {
            return response()->json([
                'message' => 'Você não está vinculado a esta filial.',
            ], 403);
        }

        $trainer->update(['active_gym_id' => $gymId]);

        $gym = Gym::find($gymId);

        return response()->json([
            'message'       => 'Filial ativa atualizada.',
            'active_gym_id' => $gymId,
            'gym'           => [
                'id'   => $gym->id,
                'name' => $gym->name,
            ],
        ]);
    }
}
