<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
    )
    ->withMiddleware(function ($middleware) {
        $middleware->alias([
            'role'       => \App\Http\Middleware\RoleMiddleware::class,
            'permission' => \App\Http\Middleware\CheckPermission::class,
        ]);

        // Log HTTP method de cada request (para diagnosticar preflight OPTIONS).
        // Remova após confirmar que o double-request é preflight CORS.
        $middleware->api(append: [
            \App\Http\Middleware\LogRequestMethod::class,
        ]);
    })
    ->withProviders([
        \App\Providers\AuthServiceProvider::class,
    ])
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, $request) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        });
    })
    ->create();