<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
use App\Models\User;
use App\Services\ChallengeService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(private readonly ChallengeService $challengeService) {}

    public function register(Request $request)
    {
        $request->validate([
            'name'        => 'required|string|max:255',
            'email'       => 'required|email|unique:users,email',
            'password'    => 'required|min:6',
            'invite_code' => 'nullable|string|max:8',
            'gym_id'      => 'nullable|exists:gyms,id',
            'weight'      => 'nullable|numeric|min:30|max:300',
            'height'      => 'nullable|numeric|min:100|max:250',
        ]);

        // Resolve a academia: invite_code > gym_id > GymUp Default
        if ($request->invite_code) {
            $gym = Gym::where('invite_code', strtoupper(trim($request->invite_code)))->first();
            $gymId = $gym?->id ?? Gym::firstOrCreate(['name' => 'GymUp Default'], ['active' => true])->id;
        } else {
            $gymId = $request->gym_id ?? Gym::firstOrCreate(
                ['name' => 'GymUp Default'],
                ['active' => true]
            )->id;
        }

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
            'gym_id'   => $gymId,
            'role'     => 'user',
        ]);

        // Atribui ao desafio ativo da academia, se houver
        $this->challengeService->assignActiveChallengeTo($user);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Usuário criado com sucesso',
            'token' => $token,
            'user' => $user
        ]);
    }

    // GET /gym/by-invite/{code}  — público
    public function gymByInvite(string $code)
    {
        $gym = Gym::where('invite_code', strtoupper(trim($code)))->first();

        if (! $gym) {
            return response()->json(['message' => 'Código de convite inválido.'], 404);
        }

        return response()->json(['id' => $gym->id, 'name' => $gym->name]);
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
        $user = $request->user();
        $gym  = $user->gym_id ? Gym::find($user->gym_id) : null;

        return response()->json([
            ...$user->only(['id', 'name', 'email', 'role', 'gym_id', 'points_balance']),
            'gym_chain_id' => $gym?->chain_id,
            'permissions'  => $user->getPermissions(),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout realizado com sucesso'
        ]);
    }
}