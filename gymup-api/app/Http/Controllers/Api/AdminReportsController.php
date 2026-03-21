<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Models\PointTransaction;
use App\Models\Redemption;
use App\Models\User;
use App\Models\WorkoutSession;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminReportsController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $admin  = $request->user();
        $period = $request->query('period', '30'); // 7 | 30 | 90
        $days   = in_array((int) $period, [7, 30, 90]) ? (int) $period : 30;

        $gymId   = $admin->gym_id;
        $start   = Carbon::today()->subDays($days - 1)->startOfDay();
        $end     = Carbon::now();

        $userIds = User::where('gym_id', $gymId)
            ->where('role', 'user')
            ->pluck('id');

        // ── KPIs ──────────────────────────────────────────────────────────────

        $totalWorkouts = WorkoutSession::whereIn('user_id', $userIds)
            ->where('points_granted', true)
            ->whereBetween('finished_at', [$start, $end])
            ->count();

        $activeUsers = WorkoutSession::whereIn('user_id', $userIds)
            ->where('points_granted', true)
            ->whereBetween('finished_at', [$start, $end])
            ->distinct('user_id')
            ->count('user_id');

        $totalCheckins = Checkin::whereIn('user_id', $userIds)
            ->whereBetween('created_at', [$start, $end])
            ->count();

        $pointsEarned = PointTransaction::where('gym_id', $gymId)
            ->where('type', 'earn')
            ->whereBetween('created_at', [$start, $end])
            ->sum('points');

        $pointsSpent = PointTransaction::where('gym_id', $gymId)
            ->where('type', 'spend')
            ->whereBetween('created_at', [$start, $end])
            ->sum('points');

        $redemptions = Redemption::whereIn('user_id', $userIds)
            ->whereBetween('created_at', [$start, $end])
            ->count();

        // ── Treinos por dia (gráfico de linha) ────────────────────────────────

        $workoutsByDay = [];
        $step = $days <= 7 ? 1 : ($days <= 30 ? 1 : 3);
        $cursor = $start->copy();

        while ($cursor->lte($end)) {
            $dayEnd = $cursor->copy()->endOfDay();
            $count  = WorkoutSession::whereIn('user_id', $userIds)
                ->where('points_granted', true)
                ->whereBetween('finished_at', [$cursor->startOfDay(), $dayEnd])
                ->count();

            $workoutsByDay[] = [
                'date'     => $cursor->format('Y-m-d'),
                'label'    => $cursor->locale('pt_BR')->isoFormat($days <= 30 ? 'D/MM' : 'D/MM'),
                'workouts' => $count,
            ];

            $cursor->addDays($step);
        }

        // ── Check-ins por dia da semana ───────────────────────────────────────

        $weekdayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
        $weekdayCounts = array_fill(0, 7, 0);

        $checkinRows = Checkin::whereIn('user_id', $userIds)
            ->whereBetween('created_at', [$start, $end])
            ->selectRaw('EXTRACT(DOW FROM created_at)::int AS dow, COUNT(*) AS cnt')
            ->groupBy('dow')
            ->get();

        foreach ($checkinRows as $row) {
            $weekdayCounts[$row->dow] = (int) $row->cnt;
        }

        $checkinsByWeekday = array_map(
            fn ($i) => ['day' => $weekdayLabels[$i], 'checkins' => $weekdayCounts[$i]],
            range(0, 6)
        );

        // ── Top alunos por treinos ────────────────────────────────────────────

        $topByWorkouts = WorkoutSession::whereIn('user_id', $userIds)
            ->where('points_granted', true)
            ->whereBetween('finished_at', [$start, $end])
            ->selectRaw('user_id, COUNT(*) AS total')
            ->groupBy('user_id')
            ->orderByDesc('total')
            ->limit(5)
            ->get()
            ->map(function ($row) {
                $user = User::find($row->user_id, ['id', 'name']);
                return [
                    'id'       => $user?->id,
                    'name'     => $user?->name ?? '—',
                    'workouts' => (int) $row->total,
                ];
            });

        // ── Top alunos por pontos ─────────────────────────────────────────────

        $topByPoints = PointTransaction::where('gym_id', $gymId)
            ->where('type', 'earn')
            ->whereIn('user_id', $userIds)
            ->whereBetween('created_at', [$start, $end])
            ->selectRaw('user_id, SUM(points) AS total')
            ->groupBy('user_id')
            ->orderByDesc('total')
            ->limit(5)
            ->get()
            ->map(function ($row) {
                $user = User::find($row->user_id, ['id', 'name']);
                return [
                    'id'     => $user?->id,
                    'name'   => $user?->name ?? '—',
                    'points' => (int) $row->total,
                ];
            });

        // ── Resgates por recompensa ───────────────────────────────────────────

        $topRedemptions = Redemption::whereIn('user_id', $userIds)
            ->whereBetween('created_at', [$start, $end])
            ->with('reward:id,name')
            ->selectRaw('reward_id, COUNT(*) AS total')
            ->groupBy('reward_id')
            ->orderByDesc('total')
            ->limit(5)
            ->get()
            ->map(fn ($r) => [
                'reward' => $r->reward?->name ?? '—',
                'count'  => (int) $r->total,
            ]);

        return response()->json([
            'period'              => $days,
            'kpis'                => [
                'total_workouts'  => $totalWorkouts,
                'active_users'    => $activeUsers,
                'total_checkins'  => $totalCheckins,
                'points_earned'   => (int) $pointsEarned,
                'points_spent'    => (int) $pointsSpent,
                'redemptions'     => $redemptions,
            ],
            'workouts_by_day'     => $workoutsByDay,
            'checkins_by_weekday' => $checkinsByWeekday,
            'top_by_workouts'     => $topByWorkouts,
            'top_by_points'       => $topByPoints,
            'top_redemptions'     => $topRedemptions,
        ]);
    }
}
