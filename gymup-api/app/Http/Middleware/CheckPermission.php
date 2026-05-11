<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckPermission
{
    /**
     * Verifica se o usuário autenticado possui a permissão informada.
     *
     * Uso nas rotas:
     *   middleware('permission:view_users')
     *   middleware('permission:edit_users,manage_rewards')   ← qualquer uma satisfaz
     */
    public function handle(Request $request, Closure $next, string ...$permissions): Response
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        foreach ($permissions as $permission) {
            if ($user->hasPermission($permission)) {
                return $next($request);
            }
        }

        return response()->json([
            'message' => 'Acesso não autorizado. Permissão insuficiente.',
        ], 403);
    }
}
