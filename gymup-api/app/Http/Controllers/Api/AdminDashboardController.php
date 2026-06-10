<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
use App\Models\GymChallenge;
use App\Models\PointTransaction;
use App\Models\Redemption;
use App\Models\User;
use App\Models\WorkoutSession;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminDashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $admin = $request->user();

        return $admin->isSuperAdmin()
            ? $this->globalDashboard($admin)
            : $this->gymDashboard($admin);
    }

    // ── Dashboard global (super_admin) ─────────────────────────────────────────

    private function globalDashboard($admin): JsonResponse
    {
        $today = Carbon::today();

        $totalGyms = Gym::where('active', true)->count();

        $totalUsers = User::where('role', 'user')->count();

        $workoutsToday = WorkoutSession::whereNotNull('finished_at')
            ->whereDate('finished_at', $today)
            ->count();

        $weeklyActivity = [];
        for ($i = 6; $i >= 0; $i--) {
            $date  = $today->copy()->subDays($i);
            $count = WorkoutSession::whereNotNull('finished_at')
                ->whereDate('finished_at', $date)
                ->count();

            $weeklyActivity[] = [
                'date'     => $date->format('Y-m-d'),
                'day'      => $date->locale('pt_BR')->isoFormat('ddd'),
                'workouts' => $count,
            ];
        }

        $topGyms = Gym::withCount(['users' => function ($q) {
                $q->where('role', 'user');
            }])
            ->where('active', true)
            ->orderByDesc('users_count')
            ->limit(5)
            ->get(['id', 'name'])
            ->map(fn ($g) => [
                'id'    => $g->id,
                'name'  => $g->name,
                'users' => $g->users_count,
            ]);

        return response()->json([
            'dashboard_type'   => 'global',
            'admin_name'       => $admin->name,
            'total_gyms'       => $totalGyms,
            'total_users'      => $totalUsers,
            'workouts_today'   => $workoutsToday,
            'weekly_activity'  => $weeklyActivity,
            'top_gyms'         => $topGyms,
        ]);
    }

    // ── Dashboard da academia (gym_admin / trainer) ────────────────────────────

    private function gymDashboard($admin): JsonResponse
    {
        $gymId = $admin->activeGymId();
        $today = Carbon::today();

        $userIds = User::where('gym_id', $gymId)
            ->where('role', 'user')
            ->pluck('id');

        $totalUsers = $userIds->count();

        $workoutsToday = WorkoutSession::whereIn('user_id', $userIds)
            ->whereNotNull('finished_at')
            ->whereDate('finished_at', $today)
            ->count();

        $activeChallenges = GymChallenge::where('gym_id', $gymId)
            ->where('status', 'active')
            ->count();

        $pointsDistributed = PointTransaction::where('gym_id', $gymId)
            ->where('type', 'earn')
            ->sum('points');

        $weeklyActivity = [];
        for ($i = 6; $i >= 0; $i--) {
            $date  = $today->copy()->subDays($i);
            $count = WorkoutSession::whereIn('user_id', $userIds)
                ->whereNotNull('finished_at')
                ->whereDate('finished_at', $date)
                ->count();

            $weeklyActivity[] = [
                'date'     => $date->format('Y-m-d'),
                'day'      => $date->locale('pt_BR')->isoFormat('ddd'),
                'workouts' => $count,
            ];
        }

        $topStudents = User::where('gym_id', $gymId)
            ->where('role', 'user')
            ->orderByDesc('points_balance')
            ->limit(5)
            ->select('id', 'name', 'points_balance')
            ->get();

        $pendingRedemptions = Redemption::where('gym_id', $gymId)
            ->where('status', 'pending')
            ->count();

        return response()->json([
            'dashboard_type'      => 'gym',
            'admin_name'          => $admin->name,
            'total_users'         => $totalUsers,
            'workouts_today'      => $workoutsToday,
            'active_challenges'   => $activeChallenges,
            'points_distributed'  => (int) $pointsDistributed,
            'weekly_activity'     => $weeklyActivity,
            'top_students'        => $topStudents,
            'pending_redemptions' => $pendingRedemptions,
        ]);
    }
}
