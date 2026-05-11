<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class GymQrController extends Controller
{
    /**
     * GET /api/admin/gym/qr
     */
    public function show(Request $request): JsonResponse
    {
        $gym = $request->user()->gym;

        if (! $gym) {
            return response()->json(['message' => 'Academia não encontrada.'], 404);
        }

        return response()->json([
            'qr_token'        => $gym->qr_token,
            'qr_generated_at' => $gym->qr_generated_at?->toIso8601String(),
        ]);
    }

    /**
     * POST /api/admin/gym/qr/regenerate
     */
    public function regenerate(Request $request): JsonResponse
    {
        $gym = $request->user()->gym;

        if (! $gym) {
            return response()->json(['message' => 'Academia não encontrada.'], 404);
        }

        $gym->update([
            'qr_token'        => (string) Str::uuid(),
            'qr_generated_at' => now(),
        ]);

        return response()->json([
            'qr_token'        => $gym->qr_token,
            'qr_generated_at' => $gym->qr_generated_at->toIso8601String(),
        ]);
    }
}
