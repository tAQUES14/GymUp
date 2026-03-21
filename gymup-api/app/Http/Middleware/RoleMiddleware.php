<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RoleMiddleware
{
    /**
     * Suporta uma ou mais roles: middleware('role:super_admin')
     * ou middleware('role:super_admin,trainer')
     */
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        $user = $request->user();

        if (!$user || !in_array($user->role, $roles, true)) {
            return response()->json([
                'message' => 'Acesso não autorizado.',
            ], 403);
        }

        return $next($request);
    }
}