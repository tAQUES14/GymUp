<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Checkin;
use App\Services\PointService;
use Illuminate\Support\Facades\Auth;

class CheckinController extends Controller
{
    // 🔹 Registrar checkin (ganha pontos)
    public function store(PointService $pointService)
    {
        $user = Auth::user();

        $today = now()->toDateString();

        // Verifica se já fez checkin hoje
        $already = Checkin::where('user_id', $user->id)
            ->whereDate('created_at', $today)
            ->exists();

        if ($already) {
            return response()->json([
                'message' => 'Check-in já realizado hoje.'
            ], 400);
        }

        // Criar checkin com gym_id e checkin_date preenchidos
        Checkin::create([
            'user_id'      => $user->id,
            'gym_id'       => $user->gym_id,
            'checkin_date' => $today,
            'checked_in_at' => now(),
        ]);

        // Adiciona 10 pontos via PointService para criar PointTransaction,
        // garantindo que o ranking por período contabilize check-ins corretamente.
        $pointService->earnPoints($user, 10, 'Check-in na academia');

        return response()->json([
            'message' => 'Check-in realizado com sucesso',
            'points_added' => 10
        ]);
    }

    // 🔹 Status do checkin
    public function status()
    {
        $user = Auth::user();
        $today = now()->toDateString();

        $jaRegistrouHoje = Checkin::where('user_id', $user->id)
            ->whereDate('created_at', $today)
            ->exists();

        return response()->json([
            'qr_validado' => true, // depois podemos melhorar
            'ja_registrou_hoje' => $jaRegistrouHoje
        ]);
    }
}