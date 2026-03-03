<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomWorkout;
use App\Models\Exercise;
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

        $this->createInitialWorkout($user);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Usuário criado com sucesso',
            'token'   => $token,
            'user'    => $user,
        ]);
    }

    /**
     * Cria o "Treino Inicial" para o novo usuário.
     * Idempotente: se o treino já existir, não duplica.
     */
    private function createInitialWorkout(User $user): void
    {
        $workout = CustomWorkout::firstOrCreate(
            [
                'user_id' => $user->id,
                'name'    => 'Treino Inicial',
            ],
            [
                'description'  => 'Treino inicial gerado automaticamente.',
                'level'        => 'beginner',
                'duration'     => 60,
                'is_generated' => true,
            ]
        );

        // Se o treino já existia, não repete os exercícios.
        if (! $workout->wasRecentlyCreated) {
            return;
        }

        $exercises = [
            ['name' => 'Supino Reto',       'muscle_group' => 'Peito'],
            ['name' => 'Agachamento Livre',  'muscle_group' => 'Pernas'],
            ['name' => 'Remada Curvada',     'muscle_group' => 'Costas'],
            ['name' => 'Rosca Direta',       'muscle_group' => 'Bíceps'],
        ];

        foreach ($exercises as $data) {
            $exercise = Exercise::firstOrCreate(
                ['name' => $data['name']],
                [
                    'muscle_group' => $data['muscle_group'],
                    'default_rest' => 60,
                ]
            );

            $workout->exercises()->attach($exercise->id, [
                'sets' => 3,
                'reps' => 12,
                'rest' => 60,
            ]);
        }
    }

    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
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
            'token'   => $token,
            'user'    => $user,
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
            'message' => 'Logout realizado com sucesso',
        ]);
    }
}
