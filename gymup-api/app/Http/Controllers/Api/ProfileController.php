<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Services\StreakService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

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
            'phone'          => Schema::hasColumn('users', 'phone') ? $user->phone : null,
            'avatar_url'     => Schema::hasColumn('users', 'avatar_url') ? $user->avatar_url : null,
            'role'           => $user->role,
            'points_balance' => (int) $user->points_balance,
            'total_checkins' => $totalCheckins,
            'current_streak' => $currentStreak,
            'weight'         => Schema::hasColumn('users', 'weight') ? $user->weight : null,
            'height'         => Schema::hasColumn('users', 'height') ? $user->height : null,
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
            'phone'  => 'nullable|string|max:30',
            'weight' => 'nullable|numeric|min:30|max:300',
            'height' => 'nullable|numeric|min:100|max:250',
        ]);

        $user = $request->user();

        $fields = collect(['name', 'phone', 'weight', 'height'])
            ->filter(fn ($field) => Schema::hasColumn('users', $field))
            ->values()
            ->all();

        $user->update($request->only($fields));
        $user->refresh();

        return response()->json([
            'message' => 'Perfil atualizado com sucesso.',
            'user'    => $user->only(['id', 'name', 'phone', 'avatar_url', 'weight', 'height']),
        ]);
    }

    public function updateAvatar(Request $request)
    {
        if (! Schema::hasColumn('users', 'avatar_url')) {
            return response()->json([
                'message' => 'A coluna avatar_url ainda nao existe na tabela users. Execute as migrations.',
            ], 409);
        }

        $request->validate([
            'avatar' => 'required|image|max:4096',
        ]);

        $path = $request->file('avatar')->store('avatars', 'public');
        $avatarUrl = url(Storage::url($path));

        $user = $request->user();
        $user->update(['avatar_url' => $avatarUrl]);

        return response()->json([
            'message'    => 'Foto atualizada com sucesso.',
            'avatar_url' => $avatarUrl,
        ]);
    }
}
