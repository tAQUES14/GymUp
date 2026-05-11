<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RoleController extends Controller
{
    // ── Roles ─────────────────────────────────────────────────────────────────

    /**
     * Lista roles da academia do usuário autenticado.
     * super_admin vê roles globais (gym_id = null).
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $roles = Role::with('permissions')
            ->when(
                $user->isSuperAdmin(),
                // super_admin: apenas roles globais (gym_id = null)
                fn ($q) => $q->whereNull('gym_id'),
                // outros admins: roles globais (templates) + roles específicos da academia
                fn ($q) => $q->where(fn ($q2) => $q2
                    ->whereNull('gym_id')
                    ->orWhere('gym_id', $user->gym_id)
                )
            )
            ->get()
            ->map(fn (Role $role) => [
                'id'          => $role->id,
                'name'        => $role->name,
                'gym_id'      => $role->gym_id,
                'is_global'   => $role->isGlobal(),
                'permissions' => $role->permissions->pluck('name'),
            ]);

        return response()->json($roles);
    }

    /**
     * Cria um novo role dentro da academia do usuário.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'        => 'required|string|max:100',
            'permissions' => 'array',
            'permissions.*' => 'string|exists:permissions,name',
        ]);

        $gymId = $request->user()->isSuperAdmin() ? null : $request->user()->gym_id;

        // Verifica duplicidade no escopo correto
        $exists = Role::where('name', $request->name)
            ->where('gym_id', $gymId)
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'Já existe um role com esse nome.'], 422);
        }

        $role = Role::create([
            'name'   => $request->name,
            'gym_id' => $gymId,
        ]);

        if ($request->filled('permissions')) {
            $ids = Permission::whereIn('name', $request->permissions)->pluck('id');
            $role->permissions()->sync($ids);
        }

        return response()->json([
            'message' => 'Role criado com sucesso.',
            'role'    => $this->formatRole($role->load('permissions')),
        ], 201);
    }

    /**
     * Retorna um role com suas permissões.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $role = $this->findRoleForUser($request->user(), $id);

        if (! $role) {
            return response()->json(['message' => 'Role não encontrado.'], 404);
        }

        return response()->json($this->formatRole($role->load('permissions')));
    }

    /**
     * Atualiza nome e permissões de um role.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $role = $this->findRoleForUser($request->user(), $id);

        if (! $role) {
            return response()->json(['message' => 'Role não encontrado.'], 404);
        }

        $request->validate([
            'name'          => 'sometimes|string|max:100',
            'permissions'   => 'array',
            'permissions.*' => 'string|exists:permissions,name',
        ]);

        if ($request->filled('name')) {
            $role->update(['name' => $request->name]);
        }

        if ($request->has('permissions')) {
            $ids = Permission::whereIn('name', $request->permissions)->pluck('id');
            $role->permissions()->sync($ids);
        }

        return response()->json([
            'message' => 'Role atualizado com sucesso.',
            'role'    => $this->formatRole($role->load('permissions')),
        ]);
    }

    /**
     * Remove um role da academia (não remove roles globais).
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $role = $this->findRoleForUser($request->user(), $id);

        if (! $role) {
            return response()->json(['message' => 'Role não encontrado.'], 404);
        }

        if ($role->isGlobal() && ! $request->user()->isSuperAdmin()) {
            return response()->json(['message' => 'Roles globais não podem ser removidos.'], 403);
        }

        $role->delete();

        return response()->json(['message' => 'Role removido com sucesso.']);
    }

    // ── Permissões disponíveis ─────────────────────────────────────────────────

    /**
     * Lista todas as permissões do sistema.
     */
    public function permissions(): JsonResponse
    {
        $permissions = Permission::orderBy('name')->get(['id', 'name', 'description']);

        return response()->json($permissions);
    }

    // ── Atribuição de roles a usuários ─────────────────────────────────────────

    /**
     * Atribui roles a um usuário da academia.
     * Body: { role_ids: [1, 2] }
     */
    public function assignToUser(Request $request, int $userId): JsonResponse
    {
        $request->validate([
            'role_ids'   => 'required|array',
            'role_ids.*' => 'integer|exists:roles,id',
        ]);

        $admin  = $request->user();
        $target = User::findOrFail($userId);

        // Garante que o admin só atribui roles à sua academia
        if (! $admin->isSuperAdmin() && $target->gym_id !== $admin->gym_id) {
            return response()->json(['message' => 'Usuário não pertence à sua academia.'], 403);
        }

        // Só permite roles da academia ou globais
        $allowedRoles = Role::whereIn('id', $request->role_ids)
            ->where(fn ($q) => $q
                ->whereNull('gym_id')
                ->orWhere('gym_id', $admin->isSuperAdmin() ? null : $admin->gym_id)
            )
            ->pluck('id');

        $target->roles()->sync($allowedRoles);

        return response()->json([
            'message'     => 'Roles atribuídos com sucesso.',
            'permissions' => $target->getPermissions(),
        ]);
    }

    /**
     * Retorna os roles e permissões efetivas de um usuário.
     */
    public function userRoles(Request $request, int $userId): JsonResponse
    {
        $admin  = $request->user();
        $target = User::with('roles.permissions')->findOrFail($userId);

        if (! $admin->isSuperAdmin() && $target->gym_id !== $admin->gym_id) {
            return response()->json(['message' => 'Usuário não pertence à sua academia.'], 403);
        }

        return response()->json([
            'user_id'            => $target->id,
            'name'               => $target->name,
            'legacy_role'        => $target->role,
            'roles'              => $target->roles->map(fn ($r) => [
                'id'          => $r->id,
                'name'        => $r->name,
                'permissions' => $r->permissions->pluck('name'),
            ]),
            'effective_permissions' => $target->getPermissions(),
        ]);
    }

    // ── Privado ────────────────────────────────────────────────────────────────

    private function findRoleForUser(User $user, int $roleId): ?Role
    {
        return Role::where('id', $roleId)
            ->when(
                $user->isSuperAdmin(),
                fn ($q) => $q->whereNull('gym_id'),
                fn ($q) => $q->where(fn ($q2) => $q2
                    ->whereNull('gym_id')
                    ->orWhere('gym_id', $user->gym_id)
                )
            )
            ->first();
    }

    private function formatRole(Role $role): array
    {
        return [
            'id'          => $role->id,
            'name'        => $role->name,
            'gym_id'      => $role->gym_id,
            'is_global'   => $role->isGlobal(),
            'permissions' => $role->permissions->pluck('name'),
        ];
    }
}
