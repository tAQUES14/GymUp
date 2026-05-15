<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminStaffController extends Controller
{
    // Perfis exibíveis/gerenciáveis nesta tela (excluídos super_admin e network_admin)
    private const STAFF_ROLES = ['gym_admin', 'trainer'];

    /**
     * GET /admin/staff
     * Lista os membros de equipe da academia (gym_admin + trainer).
     */
    public function index(Request $request): JsonResponse
    {
        $gymId = $request->user()->activeGymId();

        $staff = User::where('gym_id', $gymId)
            ->whereIn('role', self::STAFF_ROLES)
            ->orderBy('name')
            ->get()
            ->map(fn ($u) => $this->formatMember($u));

        return response()->json(['staff' => $staff]);
    }

    /**
     * POST /admin/staff
     * Cria um novo membro de equipe e retorna a senha temporária para ser compartilhada.
     */
    public function store(Request $request): JsonResponse
    {
        $gymId = $request->user()->activeGymId();

        $request->validate([
            'name'  => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'role'  => ['required', Rule::in(self::STAFF_ROLES)],
        ]);

        $tempPassword = 'GymUp@' . random_int(100_000, 999_999);

        $member = User::create([
            'name'       => $request->name,
            'email'      => $request->email,
            'password'   => Hash::make($tempPassword),
            'gym_id'     => $gymId,
            'role'       => $request->role,
            'invited_at' => now(),
            // email_verified_at permanece null até o primeiro login
        ]);

        return response()->json([
            'member'        => $this->formatMember($member),
            'temp_password' => $tempPassword,
        ], 201);
    }

    /**
     * PUT /admin/staff/{id}
     * Atualiza nome e/ou perfil de um membro.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $gymId  = $request->user()->activeGymId();
        $member = $this->findStaff($gymId, $id);

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'role' => ['sometimes', 'required', Rule::in(self::STAFF_ROLES)],
        ]);

        $member->update($request->only(['name', 'role']));

        return response()->json(['member' => $this->formatMember($member->fresh())]);
    }

    /**
     * DELETE /admin/staff/{id}
     * Remove o acesso de um membro (deleta conta).
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $gymId  = $request->user()->activeGymId();
        $member = $this->findStaff($gymId, $id);

        if ($member->id === $request->user()->id) {
            return response()->json(['message' => 'Não é possível remover o próprio acesso.'], 403);
        }

        $member->delete();

        return response()->json(['message' => 'Acesso removido com sucesso.']);
    }

    /**
     * POST /admin/staff/{id}/resend-invite
     * Gera nova senha temporária para membro que ainda não fez login.
     */
    public function resendInvite(Request $request, int $id): JsonResponse
    {
        $gymId  = $request->user()->activeGymId();
        $member = $this->findStaff($gymId, $id);

        if ($member->email_verified_at) {
            return response()->json(['message' => 'Este membro já acessou o sistema.'], 422);
        }

        $tempPassword = 'GymUp@' . random_int(100_000, 999_999);

        $member->update([
            'password'   => Hash::make($tempPassword),
            'invited_at' => now(),
        ]);

        return response()->json([
            'message'       => 'Novas credenciais geradas com sucesso.',
            'temp_password' => $tempPassword,
        ]);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function findStaff(int $gymId, int $id): User
    {
        return User::where('gym_id', $gymId)
            ->whereIn('role', self::STAFF_ROLES)
            ->findOrFail($id);
    }

    private function formatMember(User $u): array
    {
        // Pendente = foi convidado mas nunca fez login
        $status = ($u->invited_at && ! $u->email_verified_at) ? 'pending' : 'active';

        return [
            'id'          => $u->id,
            'name'        => $u->name,
            'email'       => $u->email,
            'role'        => $u->role,
            'status'      => $status,
            'invited_at'  => $u->invited_at?->toDateString(),
            'created_at'  => $u->created_at?->toDateString(),
        ];
    }
}
