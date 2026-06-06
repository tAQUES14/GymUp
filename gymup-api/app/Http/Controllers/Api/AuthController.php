<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
use App\Models\User;
use App\Services\ChallengeService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
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

    public function google(Request $request)
    {
        $request->validate([
            'id_token'    => 'required|string',
            'invite_code' => 'nullable|string|max:8',
        ]);

        $profile = $this->verifyGoogleToken($request->id_token);
        $email = strtolower((string) ($profile['email'] ?? ''));

        if ($email === '') {
            return response()->json(['message' => 'Nao foi possivel obter o email do Google.'], 422);
        }

        $user = User::where('email', $email)->first();

        if (! $user && ! $request->filled('invite_code')) {
            return response()->json([
                'needs_invite' => true,
                'profile' => [
                    'name' => $profile['name'] ?? strtok($email, '@'),
                    'email' => $email,
                    'picture' => $profile['picture'] ?? null,
                ],
            ]);
        }

        if (! $user) {
            $gym = Gym::where('invite_code', strtoupper(trim($request->invite_code)))->first();

            if (! $gym) {
                return response()->json([
                    'message' => 'Codigo de convite invalido.',
                ], 422);
            }

            $payload = [
                'name' => $profile['name'] ?? strtok($email, '@'),
                'email' => $email,
                'password' => Hash::make(Str::random(48)),
                'gym_id' => $gym->id,
                'role' => 'user',
                'email_verified_at' => now(),
            ];

            if (Schema::hasColumn('users', 'avatar_url')) {
                $payload['avatar_url'] = $profile['picture'] ?? null;
            }

            $user = User::create($payload);

            $this->challengeService->assignActiveChallengeTo($user);
        } elseif (! $user->email_verified_at) {
            $user->email_verified_at = now();
            $user->save();
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login com Google realizado com sucesso',
            'needs_invite' => false,
            'token' => $token,
            'user' => $user,
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

        // Marca primeiro login (usado para detectar convites de staff pendentes)
        if (! $user->email_verified_at) {
            $user->email_verified_at = now();
            $user->save();
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login realizado com sucesso',
            'token' => $token,
            'user' => $user
        ]);
    }

    private function verifyGoogleToken(string $idToken): array
    {
        $response = Http::timeout(8)->get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if (! $response->ok()) {
            throw ValidationException::withMessages([
                'google' => ['Token do Google invalido.'],
            ]);
        }

        $payload = $response->json();

        if (($payload['email_verified'] ?? 'false') !== 'true' && ($payload['email_verified'] ?? false) !== true) {
            throw ValidationException::withMessages([
                'google' => ['Email do Google ainda nao foi verificado.'],
            ]);
        }

        $allowedAudiences = collect(explode(',', (string) config('services.google.client_ids')))
            ->map(fn ($id) => trim($id))
            ->filter()
            ->values();

        if ($allowedAudiences->isNotEmpty() && ! $allowedAudiences->contains($payload['aud'] ?? null)) {
            throw ValidationException::withMessages([
                'google' => ['Cliente Google nao autorizado.'],
            ]);
        }

        return $payload;
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
