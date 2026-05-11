<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
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
        $scope  = $request->query('scope', 'gym');

        $chainId = null;
        if ($scope === 'chain') {
            $gym     = Gym::find($user->gym_id);
            $chainId = $gym?->chain_id;

            if (! $chainId) {
                return response()->json(['message' => 'Academia não pertence a uma rede'], 400);
            }
        }

        if ($period === 'progress') {
            return response()->json($this->progressRanking($user, $limit, $scope, $chainId));
        }

        $startDate = match ($period) {
            'weekly'    => now()->startOfWeek(),
            'monthly'   => now()->startOfMonth(),
            'quarterly' => now()->subDays(90),
            default     => null,
        };

        $query = DB::table('users')
            ->where('users.role', 'user')
            ->leftJoin('point_transactions', function ($join) use ($startDate) {
                $join->on('point_transactions.user_id', '=', 'users.id')
                     ->where('point_transactions.type', '=', 'earn');

                if ($startDate) {
                    $join->where('point_transactions.created_at', '>=', $startDate);
                }
            });

        $select  = [
            'users.id',
            'users.name',
            'users.current_streak',
            DB::raw('COALESCE(SUM(point_transactions.points), 0) as points'),
        ];
        $groupBy = ['users.id', 'users.name', 'users.current_streak'];

        if ($scope === 'chain') {
            $query->join('gyms', 'gyms.id', '=', 'users.gym_id')
                  ->where('gyms.chain_id', $chainId);
            $select[]  = 'gyms.name as gym_name';
            $groupBy[] = 'gyms.name';
        } else {
            $query->where('users.gym_id', $user->gym_id);
        }

        $users = $query->select($select)
            ->groupBy($groupBy)
            ->orderByDesc('points')
            ->orderBy('users.name')
            ->limit($limit)
            ->get();

        $includeGymName = $scope === 'chain';

        $ranking = $users->values()->map(function ($u, $index) use ($includeGymName) {
            $item = [
                'position'   => $index + 1,
                'user_id'    => $u->id,
                'name'       => $u->name,
                'points'     => (int) $u->points,
                'streak'     => (int) $u->current_streak,
                'growth_pct' => null,
            ];
            if ($includeGymName) {
                $item['gym_name'] = $u->gym_name ?? null;
            }
            return $item;
        });

        return response()->json($ranking);
    }

    private function progressRanking($user, int $limit, string $scope = 'gym', ?int $chainId = null): array
    {
        $weekStart     = now()->startOfWeek();
        $prevWeekStart = now()->subWeek()->startOfWeek();

        $currentSub = DB::table('point_transactions')
            ->where('type', 'earn')
            ->where('created_at', '>=', $weekStart)
            ->select('user_id', DB::raw('SUM(points) as pts'))
            ->groupBy('user_id');

        $previousSub = DB::table('point_transactions')
            ->where('type', 'earn')
            ->where('created_at', '>=', $prevWeekStart)
            ->where('created_at', '<', $weekStart)
            ->select('user_id', DB::raw('SUM(points) as pts'))
            ->groupBy('user_id');

        $query = DB::table('users')
            ->where('users.role', 'user')
            ->leftJoinSub($currentSub, 'curr', 'curr.user_id', '=', 'users.id')
            ->leftJoinSub($previousSub, 'prev', 'prev.user_id', '=', 'users.id');

        $select = [
            'users.id',
            'users.name',
            'users.current_streak',
            DB::raw('COALESCE(curr.pts, 0) as current_pts'),
            DB::raw('COALESCE(prev.pts, 0) as previous_pts'),
            DB::raw("
                CASE
                    WHEN COALESCE(prev.pts, 0) = 0 AND COALESCE(curr.pts, 0) > 0
                        THEN 999
                    WHEN COALESCE(prev.pts, 0) = 0
                        THEN 0
                    ELSE ROUND(
                        ((COALESCE(curr.pts, 0) - COALESCE(prev.pts, 0)) * 100.0)
                        / COALESCE(prev.pts, 0)
                    )
                END as growth_pct
            "),
        ];
        $groupBy = ['users.id', 'users.name', 'users.current_streak'];

        if ($scope === 'chain') {
            $query->join('gyms', 'gyms.id', '=', 'users.gym_id')
                  ->where('gyms.chain_id', $chainId);
            $select[]  = 'gyms.name as gym_name';
            $groupBy[] = 'gyms.name';
        } else {
            $query->where('users.gym_id', $user->gym_id);
        }

        $rows = $query->select($select)
            ->groupBy($groupBy)
            ->orderByDesc('growth_pct')
            ->orderByDesc('current_pts')
            ->orderBy('users.name')
            ->limit($limit)
            ->get();

        $includeGymName = $scope === 'chain';

        return $rows->values()->map(function ($u, $index) use ($includeGymName) {
            $item = [
                'position'   => $index + 1,
                'user_id'    => $u->id,
                'name'       => $u->name,
                'points'     => (int) $u->current_pts,
                'streak'     => (int) $u->current_streak,
                'growth_pct' => (int) $u->growth_pct,
            ];
            if ($includeGymName) {
                $item['gym_name'] = $u->gym_name ?? null;
            }
            return $item;
        })->all();
    }
}
