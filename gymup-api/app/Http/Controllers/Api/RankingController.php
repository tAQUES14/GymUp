<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class RankingController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $limit = (int) $request->query('limit', 10);
        $limit = max(1, min($limit, 50));

        $period = $request->query('period', 'all');

        $startDate = match ($period) {
            'weekly'    => now()->startOfWeek()->toDateString(),
            'monthly'   => now()->startOfMonth()->toDateString(),
            'quarterly' => now()->subDays(90)->toDateString(),
            default     => null,
        };

        $query = User::where('gym_id', $user->gym_id)
            ->where('role', 'student')
            ->select('id', 'name', 'points_balance');

        if ($startDate) {
            $query->withCount(['checkins as period_checkins_count' => function ($q) use ($startDate) {
                $q->where('checkin_date', '>=', $startDate);
            }])->orderByDesc('period_checkins_count');
        } else {
            $query->orderByDesc('points_balance');
        }

        $users = $query->limit($limit)->get();

        $ranking = $users->values()->map(function ($u, $index) use ($startDate) {
            $points = $startDate
                ? ($u->period_checkins_count ?? 0) * 10
                : $u->points_balance;

            return [
                'position' => $index + 1,
                'user_id'  => $u->id,
                'name'     => $u->name,
                'points'   => $points,
                'streak'   => 0,
            ];
        });

        return response()->json($ranking);
    }
}
