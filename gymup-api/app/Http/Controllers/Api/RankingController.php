<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RankingController extends Controller
{
    private const FALLBACK_PUBLIC_STORAGE_BASE_URL = 'https://s3.us-west-004.backblazeb2.com/gymup-storage';

    public function index(Request $request)
    {
        $user = $request->user();

        $limit = (int) $request->query('limit', 10);
        $limit = max(1, min($limit, 50));

        $period = $request->query('period', 'all');
        $scope  = $request->query('scope', 'gym');
        $rankBy = $request->query('rank_by', 'points');
        $rankBy = in_array($rankBy, ['points', 'streak'], true) ? $rankBy : 'points';

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

        // Rank by activity earn transactions only.
        // Exclude category='redemption' (refunds from rejected redemptions)
        // so a reject+resubmit cycle does not inflate a user's score.
        $query = DB::table('users')
            ->where('users.role', 'user')
            ->leftJoin('point_transactions', function ($join) use ($startDate) {
                $join->on('point_transactions.user_id', '=', 'users.id')
                     ->where('point_transactions.type', '=', 'earn')
                     ->where('point_transactions.category', '!=', 'redemption');

                if ($startDate) {
                    $join->where('point_transactions.created_at', '>=', $startDate);
                }
            });

        $select  = [
            'users.id',
            'users.name',
            'users.avatar_url',
            'users.current_streak',
            DB::raw('COALESCE(SUM(point_transactions.points), 0) as points'),
        ];
        $groupBy = ['users.id', 'users.name', 'users.avatar_url', 'users.current_streak'];

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
            ->when(
                $rankBy === 'streak',
                fn ($q) => $q->orderByDesc('users.current_streak')->orderByDesc('points'),
                fn ($q) => $q->orderByDesc('points')->orderByDesc('users.current_streak')
            )
            ->orderBy('users.name')
            ->limit($limit)
            ->get();

        $includeGymName = $scope === 'chain';

        $ranking = $users->values()->map(function ($u, $index) use ($includeGymName) {
            $item = [
                'position'   => $index + 1,
                'user_id'    => $u->id,
                'name'       => $u->name,
                'avatar_url' => $this->avatarUrl($u->avatar_url ?? null),
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

    private function progressRanking(User $user, int $limit, string $scope = 'gym', ?int $chainId = null): array
    {
        $weekStart     = now()->startOfWeek();
        $prevWeekStart = now()->subWeek()->startOfWeek();

        $currentSub = DB::table('point_transactions')
            ->where('type', 'earn')
            ->where('category', '!=', 'redemption')
            ->where('created_at', '>=', $weekStart)
            ->select('user_id', DB::raw('SUM(points) as pts'))
            ->groupBy('user_id');

        $previousSub = DB::table('point_transactions')
            ->where('type', 'earn')
            ->where('category', '!=', 'redemption')
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
            'users.avatar_url',
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
        $groupBy = ['users.id', 'users.name', 'users.avatar_url', 'users.current_streak'];

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
                'avatar_url' => $this->avatarUrl($u->avatar_url ?? null),
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

    private function avatarUrl(?string $value): ?string
    {
        if (! $value) {
            return null;
        }

        if (str_starts_with($value, 'http') && ! str_contains($value, 'gymup-api.onrender.com/storage')) {
            return $value;
        }

        $path = $this->normalizeAvatarPath($value);
        if (! $path) {
            return null;
        }

        $encoded = implode('/', array_map('rawurlencode', explode('/', $path)));
        return rtrim($this->publicStorageBaseUrl(), '/') . '/' . $encoded;
    }

    private function normalizeAvatarPath(string $value): string
    {
        if (! str_starts_with($value, 'http')) {
            return ltrim($value, '/');
        }

        $path = rawurldecode(parse_url($value, PHP_URL_PATH) ?: '');

        if (preg_match('#/(?:storage|img)/(.+)$#', $path, $matches)) {
            return ltrim($matches[1], '/');
        }

        if (preg_match('#/(avatars/.+)$#', $path, $matches)) {
            return ltrim($matches[1], '/');
        }

        return ltrim($path, '/');
    }

    private function publicStorageBaseUrl(): string
    {
        $publicDisk = config('filesystems.disks.public', []);
        $publicUrl = env('PUBLIC_DISK_URL');

        if (! $publicUrl && ($publicDisk['driver'] ?? null) === 's3') {
            $endpoint = $publicDisk['endpoint'] ?? null;
            $bucket = $publicDisk['bucket'] ?? null;

            if ($endpoint && $bucket) {
                $publicUrl = rtrim($endpoint, '/') . '/' . $bucket;
            }
        }

        $publicUrl ??= $publicDisk['url'] ?? null;

        if (! $publicUrl || str_contains($publicUrl, 'gymup-api.onrender.com/storage')) {
            return self::FALLBACK_PUBLIC_STORAGE_BASE_URL;
        }

        return $publicUrl;
    }
}
