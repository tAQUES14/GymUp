<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use Illuminate\Support\Facades\Auth;

class CheckinController extends Controller
{
    /**
     * POST /api/checkin
     *
     * Registers a check-in for the authenticated user.
     * Check-in alone does NOT generate points — points are only awarded
     * when a valid workout is completed on the same day.
     */
    public function store()
    {
        $user  = Auth::user();
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
            'gym_id'        => $user->gym_id,
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
