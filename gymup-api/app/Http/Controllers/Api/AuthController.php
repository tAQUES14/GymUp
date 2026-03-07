<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|min:6',
            'gym_id'   => 'nullable|exists:gyms,id',
            'weight'   => 'nullable|numeric|min:30|max:300',
            'height'   => 'nullable|numeric|min:100|max:250',
        ]);

        // Usa a gym informada ou garante que a gym padrão existe.
        // Torna o sistema resiliente mesmo sem executar seeders.
        $gymId = $request->gym_id ?? Gym::firstOrCreate(
            ['name' => 'GymUp Default'],
            ['active' => true]
        )->id;

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'gym_id'   => $gymId,
            'role'     => 'student',
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Usuário criado com sucesso',
            'token' => $token,
            'user' => $user
        ]);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Credenciais inválidas.'],
            ]);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login realizado com sucesso',
            'token' => $token,
            'user' => $user
        ]);
    }

    public function me(Request $request)
    {
        return response()->json($request->user()->only([
            'id', 'name', 'email', 'role', 'gym_id', 'points_balance',
        ]));
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout realizado com sucesso'
        ]);
    }
}