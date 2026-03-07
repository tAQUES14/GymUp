<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PointTransaction;
use Illuminate\Http\Request;

class PointController extends Controller
{
    /**
     * GET /api/points/history
     *
     * Returns paginated point transaction history with optional filters.
     * Supports: ?per_page=10&category=workout&period=weekly
     */
    public function history(Request $request)
    {
        $user = $request->user();

        $perPage = (int) $request->query('per_page', 10);
        $perPage = max(1, min($perPage, 50));

        $query = PointTransaction::where('user_id', $user->id)
            ->orderByDesc('created_at');

        // Filter by category (workout, bonus, streak, pr, checkin, redemption)
        if ($request->filled('category')) {
            $query->where('category', $request->query('category'));
        }

        // Filter by type (earn, spend)
        if ($request->filled('type')) {
            $query->where('type', $request->query('type'));
        }

        // Filter by period
        $period = $request->query('period');
        if ($period) {
            $startDate = match ($period) {
                'weekly'    => now()->startOfWeek(),
                'monthly'   => now()->startOfMonth(),
                'quarterly' => now()->subDays(90),
                default     => null,
            };

            if ($startDate) {
                $query->where('created_at', '>=', $startDate);
            }
        }

        $history = $query->select('id', 'type', 'category', 'points', 'description', 'reference_id', 'created_at')
            ->paginate($perPage);

        return response()->json($history);
    }
}
