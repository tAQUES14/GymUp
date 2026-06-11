<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminRankingController extends Controller
{
    /**
     * GET /api/admin/ranking?period=all|weekly|monthly|quarterly&limit=50
     *
     * Ranking de pontos dos alunos da academia.
     */
    public function index(Request $request)
    {
        $gymId  = $request->user()->activeGymId();
        $period = $request->query('period', 'all');
        $limit  = min((int) $request->query('limit', 50), 100);
        $rankBy = $request->query('rank_by', 'points');
        $rankBy = in_array($rankBy, ['points', 'streak'], true) ? $rankBy : 'points';

        $startDate = match ($period) {
            'weekly'    => now()->startOfWeek(),
            'monthly'   => now()->startOfMonth(),
            'quarterly' => now()->subDays(90),
            default     => null,
        };

        // Subquery: total workout sessions per user
        $sessionsSub = DB::table('workout_sessions')
            ->select('user_id', DB::raw('COUNT(*) as total_workouts'))
            ->groupBy('user_id');

        $ranking = DB::table('users')
            ->where('users.gym_id', $gymId)
            ->where('users.role', 'user')
            ->leftJoin('point_transactions', function ($join) use ($startDate) {
                $join->on('point_transactions.user_id', '=', 'users.id')
                     ->where('point_transactions.type', 'earn');
                if ($startDate) {
                    $join->where('point_transactions.created_at', '>=', $startDate);
                }
            })
            ->leftJoinSub($sessionsSub, 'ws', 'ws.user_id', '=', 'users.id')
            ->select(
                'users.id',
                'users.name',
                'users.email',
                'users.points_balance',
                'users.current_streak',
                DB::raw('COALESCE(SUM(point_transactions.points), 0) as period_points'),
                DB::raw('COALESCE(ws.total_workouts, 0) as workouts_count')
            )
            ->groupBy(
                'users.id',
                'users.name',
                'users.email',
                'users.points_balance',
                'users.current_streak',
                'ws.total_workouts'
            )
            ->when(
                $rankBy === 'streak',
                fn ($q) => $q->orderByDesc('users.current_streak')->orderByDesc('period_points'),
                fn ($q) => $q->orderByDesc('period_points')->orderByDesc('users.points_balance')
            )
            ->orderBy('users.name')
            ->limit($limit)
            ->get()
            ->values()
            ->map(fn($u, $i) => [
                'position'       => $i + 1,
                'user_id'        => $u->id,
                'name'           => $u->name,
                'email'          => $u->email,
                'period_points'  => (int) $u->period_points,
                'points_balance' => (int) $u->points_balance,
                'weekly_streak'  => (int) $u->current_streak,
                'current_streak' => (int) $u->current_streak,
                'workouts_count' => (int) $u->workouts_count,
            ]);

        // Summary stats
        $totalPoints = $ranking->sum('period_points');
        $activeCount = $ranking->filter(fn($r) => $r['period_points'] > 0)->count();

        return response()->json([
            'ranking'      => $ranking,
            'period'       => $period,
            'total_users'  => $ranking->count(),
            'total_points' => $totalPoints,
            'active_count' => $activeCount,
        ]);
    }
}
