<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Models\WorkoutSession;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $user   = $request->user();
        $userId = $user->id;
        $today  = Carbon::today()->toDateString();

        // ── Checkin data (keeps backward-compat streak / total_checkins) ───────
        $dates = Checkin::where('user_id', $userId)
            ->orderBy('checkin_date', 'desc')
            ->pluck('checkin_date')
            ->map(fn($d) => Carbon::parse($d)->toDateString())
            ->all();

        $totalCheckins = count($dates);

        // has_checked_in_today: true se o usuário iniciou alguma sessão de treino hoje.
        // A tabela Checkin é legada e nunca populada pelo fluxo atual do app (QR → startWorkout).
        $hasCheckedInToday = WorkoutSession::where('user_id', $userId)
            ->whereDate('started_at', $today)
            ->exists();

        $streak   = 0;
        $expected = in_array($today, $dates, true) ? Carbon::today() : Carbon::yesterday();
        foreach ($dates as $dateStr) {
            $date = Carbon::parse($dateStr);
            if ($date->equalTo($expected)) {
                $streak++;
                $expected = $expected->subDay();
            } elseif ($date->lt($expected)) {
                break;
            }
        }

        // ── Workout-based fields ───────────────────────────────────────────────
        $hasCompletedToday = WorkoutSession::where('user_id', $userId)
            ->where('points_granted', true)
            ->whereDate('started_at', $today)
            ->exists();

        $hasActiveSession = WorkoutSession::where('user_id', $userId)
            ->whereNull('finished_at')
            ->exists();

        return response()->json([
            // New dashboard fields
            'points_balance'       => $user->points_balance,
            'has_completed_today'  => $hasCompletedToday,
            'has_active_session'   => $hasActiveSession,
            'has_checked_in_today' => $hasCheckedInToday,
            'weekly_progress'      => $this->getWeeklyProgress($userId),
            'recent_activities'    => $this->getRecentActivities($userId),
            // Legacy fields kept for backward compatibility
            'streak'               => $streak,
            'total_checkins'       => $totalCheckins,
        ]);
    }

    private function getWeeklyProgress(int $userId): array
    {
        $startOfWeek = Carbon::now()->startOfWeek(Carbon::MONDAY);
        $endOfWeek   = Carbon::now()->endOfWeek(Carbon::SUNDAY);

        $sessions = WorkoutSession::where('user_id', $userId)
            ->whereNotNull('finished_at')
            ->whereBetween('finished_at', [$startOfWeek, $endOfWeek])
            ->get(['finished_at']);

        // dayOfWeekIso: 1 = Monday ... 7 = Sunday
        $trainedDays = $sessions
            ->map(fn($s) => $s->finished_at->dayOfWeekIso)
            ->unique()
            ->all();

        // Index 0 = Monday, index 6 = Sunday
        return array_map(fn($day) => in_array($day, $trainedDays), range(1, 7));
    }

    private function getRecentActivities(int $userId): array
    {
        $dailyPoints = (int) config('workout.daily_points', 10);

        $sessions = WorkoutSession::where('user_id', $userId)
            ->whereNotNull('finished_at')
            ->orderBy('finished_at', 'desc')
            ->limit(5)
            ->get(['finished_at', 'points_granted']);

        return $sessions->map(fn($s) => [
            'type'   => 'workout',
            'date'   => $s->finished_at->toIso8601String(),
            'points' => $s->points_granted ? $dailyPoints : 0,
        ])->all();
    }
}
