<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Services\StreakService;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request, StreakService $streakService)
    {
        $user = $request->user()->load('gym:id,name');

        $totalCheckins = Checkin::where('user_id', $user->id)->count();

        $currentStreak = $streakService->getStreakState($user)['streak'];

        return response()->json([
            'id'             => $user->id,
            'name'           => $user->name,
            'email'          => $user->email,
            'role'           => $user->role,
            'points_balance' => (int) $user->points_balance,
            'total_checkins' => $totalCheckins,
            'current_streak' => $currentStreak,
            'weight'         => $user->weight,
            'height'         => $user->height,
            'gym'            => $user->gym ? [
                'id'   => $user->gym->id,
                'name' => $user->gym->name,
            ] : null,
        ]);
    }

    /**
     * PUT /api/profile
     *
     * Update user profile fields with proper validation.
     */
    public function update(Request $request)
    {
        $request->validate([
            'name'   => 'nullable|string|max:255',
            'weight' => 'nullable|numeric|min:30|max:300',
            'height' => 'nullable|numeric|min:100|max:250',
        ]);

        $user = $request->user();

        $user->update($request->only(['name', 'weight', 'height']));

        return response()->json([
            'message' => 'Perfil atualizado com sucesso.',
            'user'    => $user->only(['id', 'name', 'weight', 'height']),
        ]);
    }
}
