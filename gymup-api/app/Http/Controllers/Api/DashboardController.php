<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Models\PointTransaction;
use App\Models\UserTrainingSchedule;
use App\Models\WorkoutSession;
use App\Services\StreakService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request, StreakService $streakService)
    {
        $user   = $request->user();
        $userId = $user->id;
        $today  = Carbon::today()->toDateString();

        // ── Check-in today (uses checkins table, the source of truth) ────────
        $hasCheckedInToday = Checkin::where('user_id', $userId)
            ->where('checkin_date', $today)
            ->exists();

        // ── Total check-ins ──────────────────────────────────────────────────
        $totalCheckins = Checkin::where('user_id', $userId)->count();

        // ── Total workouts concluídos (todos) ────────────────────────────────
        $totalWorkouts = WorkoutSession::where('user_id', $userId)
            ->whereNotNull('finished_at')
            ->count();

        // ── Total workouts com pontos ─────────────────────────────────────────
        $totalWorkoutsWithPoints = WorkoutSession::where('user_id', $userId)
            ->where('points_granted', true)
            ->count();

        // ── Streak semanal (inclui rotação de semana e snapshot de meta) ─────
        $streakState = $streakService->getStreakState($user);

        // ── Agenda de treino do usuário ────────────────────────────────────
        $trainingDays = UserTrainingSchedule::where('user_id', $userId)
            ->orderBy('day_of_week')
            ->pluck('day_of_week')
            ->toArray();

        // ── Workout-based fields ─────────────────────────────────────────────
        // Use finished_at for consistency with StreakService — the workout
        // counts for the day it was completed, not the day it was started.
        $hasCompletedToday = WorkoutSession::where('user_id', $userId)
            ->where('points_granted', true)
            ->whereDate('finished_at', $today)
            ->exists();

        $hasActiveSession = WorkoutSession::where('user_id', $userId)
            ->whereNull('finished_at')
            ->exists();

        return response()->json([
            'name'                 => $user->name,
            'points_balance'       => (int) $user->points_balance,
            'has_completed_today'  => $hasCompletedToday,
            'has_active_session'   => $hasActiveSession,
            'has_checked_in_today' => $hasCheckedInToday,
            'weekly_progress'      => $this->getWeeklyProgress($userId),
            'recent_activities'    => $this->getRecentActivities($userId),
            'streak'                        => $streakState['streak'],
            'best_streak'                   => $streakState['best_streak'],
            'training_days'                 => $trainingDays,
            'remaining_workouts_this_week'  => $streakState['remaining_workouts_this_week'],
            'weekly_goal'                   => $streakState['weekly_goal'],
            'total_checkins'              => $totalCheckins,
            'total_workouts'              => $totalWorkouts,
            'total_workouts_with_points'  => $totalWorkoutsWithPoints,
        ]);
    }

    private function getWeeklyProgress(int $userId): array
    {
        $startOfWeek = Carbon::now()->startOfWeek(Carbon::MONDAY);
        $endOfWeek   = Carbon::now()->endOfWeek(Carbon::SUNDAY);

        $sessions = WorkoutSession::where('user_id', $userId)
            ->where('points_granted', true)
            ->whereNotNull('finished_at')
            ->whereBetween('finished_at', [$startOfWeek, $endOfWeek])
            ->get(['finished_at']);

        $trainedDays = $sessions
            ->map(fn($s) => $s->finished_at->dayOfWeekIso)
            ->unique()
            ->all();

        return array_map(fn($day) => in_array($day, $trainedDays), range(1, 7));
    }

    private function getRecentActivities(int $userId): array
    {
        $sessions = WorkoutSession::where('user_id', $userId)
            ->whereNotNull('finished_at')
            ->orderBy('finished_at', 'desc')
            ->limit(5)
            ->get(['id', 'finished_at', 'points_granted']);

        if ($sessions->isEmpty()) {
            return [];
        }

        // BUG 6 fix: use actual points from point_transactions (includes bonuses).
        $pointsBySession = PointTransaction::where('user_id', $userId)
            ->whereIn('reference_id', $sessions->pluck('id')->all())
            ->where('type', 'earn')
            ->selectRaw('reference_id, SUM(points) as total')
            ->groupBy('reference_id')
            ->pluck('total', 'reference_id');

        return $sessions->map(fn($s) => [
            'type'   => 'workout',
            'date'   => $s->finished_at->toIso8601String(),
            'points' => (int) ($s->points_granted ? ($pointsBySession[$s->id] ?? 0) : 0),
        ])->all();
    }
}
