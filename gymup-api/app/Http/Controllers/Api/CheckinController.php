<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Models\Gym;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CheckinController extends Controller
{
    /**
     * POST /api/checkin
     *
     * Registra o check-in do dia para o usuário autenticado.
     *
     * Se `qr_token` for fornecido no body, valida que ele corresponde ao
     * qr_token da academia do usuário — impede check-in com QR de outra academia.
     * Se omitido, o check-in é aceito normalmente (compatibilidade com clientes antigos).
     *
     * Check-in sozinho NÃO gera pontos — pontos são concedidos apenas ao
     * concluir um treino válido no mesmo dia.
     */
    public function store(Request $request)
    {
        $user         = Auth::user();
        $checkinGymId = $user->gym_id; // default: filial principal

        if ($request->filled('qr_token')) {
            $scannedGym = Gym::where('qr_token', $request->input('qr_token'))->first();

            if (! $scannedGym) {
                return response()->json([
                    'message' => 'QR Code inválido para esta academia.',
                ], 403);
            }

            $homeGym      = $user->gym;
            $scannedChain = $scannedGym->chain_id;
            $homeChain    = $homeGym?->chain_id;

            $bothChainless = ($scannedChain === null && $homeChain === null);
            $sameChain     = ($scannedChain !== null && $homeChain !== null && $scannedChain == $homeChain);

            if ($bothChainless) {
                if ($scannedGym->id != $user->gym_id) {
                    return response()->json([
                        'message' => 'QR Code não pertence à sua academia.',
                    ], 403);
                }
            } elseif (! $sameChain) {
                return response()->json([
                    'message' => 'QR Code não pertence à sua rede.',
                ], 403);
            }

            $checkinGymId = $scannedGym->id;
        }

        $today = now()->toDateString();

        $already = Checkin::where('user_id', $user->id)
            ->where('checkin_date', $today)
            ->exists();

        if ($already) {
            return response()->json([
                'message' => 'Check-in já realizado hoje.',
            ], 409);
        }

        Checkin::create([
            'user_id'       => $user->id,
            'gym_id'        => $checkinGymId,
            'checkin_date'  => $today,
            'checked_in_at' => now(),
        ]);

        return response()->json([
            'message' => 'Check-in realizado com sucesso. Complete seu treino para ganhar pontos!',
        ]);
    }

    /**
     * GET /api/checkin/status
     */
    public function status()
    {
        $user  = Auth::user();
        $today = now()->toDateString();

        $checkedInToday = Checkin::where('user_id', $user->id)
            ->where('checkin_date', $today)
            ->exists();

        return response()->json([
            'checked_in_today' => $checkedInToday,
        ]);
    }
}
