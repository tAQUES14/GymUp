<?php

namespace App\Http\Controllers\Api;

use App\Services\PointService;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Checkin;
use Illuminate\Support\Facades\DB;

class CheckinController extends Controller
{
    public function store(Request $request, PointService $pointService)
    {
        $user = $request->user();
        $today = now()->toDateString();

        $alreadyCheckedIn = Checkin::where('user_id', $user->id)
            ->where('checkin_date', $today)
            ->exists();

        if ($alreadyCheckedIn) {
            return response()->json([
                'message' => 'Você já fez check-in hoje.',
            ], 409);
        }

        $pointsEarned = 10;

        DB::transaction(function () use ($user, $today, $pointsEarned, $pointService) {
            Checkin::create([
                'user_id'       => $user->id,
                'gym_id'        => $user->gym_id,
                'checkin_date'  => $today,
                'checked_in_at' => now(),
            ]);

            $pointService->earnPoints($user, $pointsEarned, 'Check-in diário');
        });

        return response()->json([
            'message'         => 'Check-in realizado com sucesso!',
            'points_earned'   => $pointsEarned,
            'points_balance'  => $user->fresh()->points_balance,
        ]);
    }
}