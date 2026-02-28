<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class LogRequestMethod
{
    public function handle(Request $request, Closure $next): Response
    {
        Log::info('REQUEST', [
            'method' => $request->method(),
            'url'    => $request->fullUrl(),
            'origin' => $request->header('Origin'),
        ]);

        return $next($request);
    }
}
