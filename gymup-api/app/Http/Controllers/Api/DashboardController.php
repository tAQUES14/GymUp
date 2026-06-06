<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Models\GymOpenDay;
use App\Models\PointTransaction;
use App\Models\UserWorkoutPlan;
use App\Models\WorkoutPlanDay;
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

        $hasCheckedInToday = Checkin::where('user_id', $userId)
            ->where('checkin_date', $today)
            ->exists();

        $totalCheckins = Checkin::where('user_id', $userId)->count();

        $totalWorkouts = WorkoutSession::where('user_id', $userId)
            ->whereNotNull('finished_at')
            ->count();

        $totalWorkoutsWithPoints = WorkoutSession::where('user_id', $userId)
            ->where('points_granted', true)
            ->count();

        $streakState = $streakService->getStreakState($user);

        $hasCompletedToday = WorkoutSession::where('user_id', $userId)
            ->where('points_granted', true)
            ->whereDate('finished_at', $today)
            ->exists();

        // Expira sessões antigas antes de verificar sessão ativa (igual ao status endpoint)
        $timeoutHours = (int) config('workout.session_timeout_hours', 4);
        WorkoutSession::where('user_id', $userId)
            ->whereNull('finished_at')
            ->where('started_at', '<', now()->subHours($timeoutHours))
            ->update(['finished_at' => now()]);

        $activeSession = WorkoutSession::activeSession()
            ->where('user_id', $userId)
            ->latest('started_at')
            ->first();

        $hasActiveSession             = $activeSession !== null;
        $activeSessionElapsedMinutes  = $activeSession ? (int) $activeSession->elapsedMinutes() : null;

        return response()->json([
            'name'                         => $user->name,
            'points_balance'               => (int) $user->points_balance,
            'has_completed_today'              => $hasCompletedToday,
            'has_active_session'               => $hasActiveSession,
            'active_session_elapsed_minutes'   => $activeSessionElapsedMinutes,
            'has_checked_in_today'             => $hasCheckedInToday,
            'weekly_progress'              => $this->getWeeklyProgress($user),
            'recent_activities'            => $this->getRecentActivities($userId),
            'streak'                       => $streakState['streak'],
            'best_streak'                  => $streakState['best_streak'],
            'remaining_workouts_this_week' => $streakState['remaining_workouts_this_week'],
            'workouts_done_this_week'      => $streakState['workouts_done_this_week'],
            'weekly_goal'                  => $streakState['weekly_goal'],
            'total_checkins'               => $totalCheckins,
            'total_workouts'               => $totalWorkouts,
            'total_workouts_with_points'   => $totalWorkoutsWithPoints,
        ]);
    }

    /**
     * Retorna o progresso semanal com contexto completo por dia (domingo → sábado).
     *
     * Cada entrada contém:
     *   - day_of_week  (0=Dom, 6=Sáb)
     *   - is_plan_day  — plano tem workout para este dia
     *   - is_rest_day  — é dia de descanso (plano ou implícito)
     *   - gym_open     — academia aberta
     *   - is_obligatory — is_plan_day && gym_open
     *   - trained      — usuário treinou (qualquer sessão com pontos)
     *   - trained_on_plan — usuário treinou e contou para streak
     */
    private function getWeeklyProgress($user): array
    {
        $userId = $user->id;

        $weekStart = Carbon::now()->startOfWeek(Carbon::SUNDAY);
        $weekEnd   = $weekStart->copy()->addDays(6)->endOfDay();

        // Sessões da semana com pontos
        $sessions = WorkoutSession::where('user_id', $userId)
            ->where('points_granted', true)
            ->whereNotNull('finished_at')
            ->whereBetween('finished_at', [$weekStart, $weekEnd])
            ->get(['finished_at', 'counts_for_streak']);

        $trainedDays = $sessions
            ->map(fn ($s) => $s->finished_at->dayOfWeek)
            ->unique()
            ->flip()
            ->all();

        $onPlanTrainedDays = $sessions
            ->where('counts_for_streak', true)
            ->map(fn ($s) => $s->finished_at->dayOfWeek)
            ->unique()
            ->flip()
            ->all();

        // Dias do plano ativo (usa scope active para respeitar effective_from)
        $planDaysByDow = [];
        $userPlan      = UserWorkoutPlan::active()->where('user_id', $userId)->first();

        if ($userPlan) {
            WorkoutPlanDay::where('plan_id', $userPlan->plan_id)
                ->get()
                ->each(function ($d) use (&$planDaysByDow) {
                    if ($d->day_of_week !== null) {
                        $planDaysByDow[$d->day_of_week] = $d;
                    }
                });
        }

        // Horários de funcionamento da academia
        $gymOpenByDow = [];
        if ($user->gym_id) {
            try {
                GymOpenDay::where('gym_id', $user->gym_id)
                    ->get()
                    ->each(function ($r) use (&$gymOpenByDow) {
                        $gymOpenByDow[$r->day_of_week] = $r->is_open;
                    });
            } catch (\Exception) {
                // Tabela gym_open_days ainda não existe — default: aberto.
            }
        }

        $result = [];
        for ($dow = 0; $dow <= 6; $dow++) {
            $planDay    = $planDaysByDow[$dow] ?? null;
            $isPlanDay  = $planDay !== null && ! $planDay->rest_day;
            $gymOpen    = $gymOpenByDow[$dow] ?? true;

            $result[] = [
                'day_of_week'     => $dow,
                'is_plan_day'     => $isPlanDay,
                'is_rest_day'     => ! $isPlanDay,
                'gym_open'        => $gymOpen,
                'is_obligatory'   => $isPlanDay && $gymOpen,
                'trained'         => isset($trainedDays[$dow]),
                'trained_on_plan' => isset($onPlanTrainedDays[$dow]),
            ];
        }

        return $result;
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

        $pointsBySession = PointTransaction::where('user_id', $userId)
            ->whereIn('reference_id', $sessions->pluck('id')->all())
            ->where('type', 'earn')
            ->selectRaw('reference_id, SUM(points) as total')
            ->groupBy('reference_id')
            ->pluck('total', 'reference_id');

        return $sessions->map(fn ($s) => [
            'type'   => 'workout',
            'date'   => $s->finished_at->toIso8601String(),
            'points' => (int) ($s->points_granted ? ($pointsBySession[$s->id] ?? 0) : 0),
        ])->all();
    }
}
