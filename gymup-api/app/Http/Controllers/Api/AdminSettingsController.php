<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AdminSettingsController extends Controller
{
    // GET /admin/settings
    public function index(Request $request): JsonResponse
    {
        $admin = $request->user();
        $gym   = $admin->gym_id ? Gym::find($admin->gym_id) : null;

        return response()->json([
            'account' => [
                'id'    => $admin->id,
                'name'  => $admin->name,
                'email' => $admin->email,
                'role'  => $admin->role,
            ],
            'gym' => $gym ? [
                'id'      => $gym->id,
                'name'    => $gym->name,
                'email'   => $gym->email,
                'phone'   => $gym->phone,
                'address' => $gym->address,
            ] : null,
        ]);
    }

    // PUT /admin/settings/gym
    public function updateGym(Request $request): JsonResponse
    {
        $admin = $request->user();

        if (!$admin->gym_id) {
            return response()->json(['message' => 'Sem academia vinculada.'], 403);
        }

        $data = $request->validate([
            'name'    => 'required|string|max:255',
            'email'   => 'nullable|email|max:255',
            'phone'   => 'nullable|string|max:30',
            'address' => 'nullable|string|max:500',
        ]);

        $gym = Gym::findOrFail($admin->gym_id);
        $gym->update($data);

        return response()->json([
            'message' => 'Dados da academia atualizados.',
            'gym'     => [
                'id'      => $gym->id,
                'name'    => $gym->name,
                'email'   => $gym->email,
                'phone'   => $gym->phone,
                'address' => $gym->address,
            ],
        ]);
    }

    // PUT /admin/settings/account
    public function updateAccount(Request $request): JsonResponse
    {
        $admin = $request->user();

        $data = $request->validate([
            'name'  => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email,' . $admin->id,
        ]);

        $admin->update($data);

        return response()->json([
            'message' => 'Conta atualizada com sucesso.',
            'account' => [
                'id'    => $admin->id,
                'name'  => $admin->name,
                'email' => $admin->email,
            ],
        ]);
    }

    // PUT /admin/settings/password
    public function updatePassword(Request $request): JsonResponse
    {
        $admin = $request->user();

        $request->validate([
            'current_password' => 'required|string',
            'new_password'     => 'required|string|min:8|confirmed',
        ]);

        if (!Hash::check($request->current_password, $admin->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['Senha atual incorreta.'],
            ]);
        }

        $admin->update(['password' => Hash::make($request->new_password)]);

        return response()->json(['message' => 'Senha alterada com sucesso.']);
    }
}
