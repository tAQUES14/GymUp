<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PointTransaction;

class PointController extends Controller
{
    public function history(Request $request)
    {
        $user = $request->user();

        $perPage = (int) $request->query('per_page', 10);
        $perPage = max(1, min($perPage, 50));

        $history = PointTransaction::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->select('id', 'type', 'points', 'description', 'created_at')
            ->paginate($perPage);

        return response()->json($history);
    }
}