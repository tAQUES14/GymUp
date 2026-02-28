<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RankingController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $limit = (int) $request->query('limit', 10);
        $limit = max(1, min($limit, 50));

        $period = $request->query('period', 'all');

        $startDate = match ($period) {
            'weekly'    => now()->startOfWeek(),
            'monthly'   => now()->startOfMonth(),
            'quarterly' => now()->subDays(90),
            default     => null,
        };

        $query = DB::table('users')
            ->where('users.gym_id', $user->gym_id)
            ->where('users.role', 'student')
            ->leftJoin('point_transactions', function ($join) use ($startDate) {
                $join->on('point_transactions.user_id', '=', 'users.id')
                     ->where('point_transactions.type', '=', 'earn');

                if ($startDate) {
                    $join->where('point_transactions.created_at', '>=', $startDate);
                }
            })
            ->select(
                'users.id',
                'users.name',
                DB::raw('COALESCE(SUM(point_transactions.points), 0) as points')
            )
            ->groupBy('users.id', 'users.name')
            ->orderByDesc('points')
            ->orderBy('users.name')
            ->limit($limit);

        $users = $query->get();

        $ranking = $users->values()->map(function ($u, $index) {
            return [
                'position' => $index + 1,
                'user_id'  => $u->id,
                'name'     => $u->name,
                'points'   => (int) $u->points,
                'streak'   => 0, // pode implementar depois
            ];
        });

        return response()->json($ranking);
    }
}