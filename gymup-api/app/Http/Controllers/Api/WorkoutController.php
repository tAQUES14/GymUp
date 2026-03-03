<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WorkoutSession;
use App\Services\PointService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WorkoutController extends Controller
{
    /**
     * POST /api/workout/start
     *
     * Starts a new workout session for the authenticated user.
     * Idempotent: if an active session already exists, returns it
     * with is_existing = true (200) instead of creating a duplicate.
     *
     * Uses DB::transaction + lockForUpdate to prevent race conditions
     * (two simultaneous requests creating two sessions).
     */
    public function start(Request $request)
    {
        $user = $request->user();

        $session = DB::transaction(function () use ($user) {
            // Pessimistic lock: blocks concurrent inserts for this user
            $active = WorkoutSession::where('user_id', $user->id)
                ->whereNull('finished_at')
                ->lockForUpdate()
                ->first();

            if ($active) {
                return $active;
            }

            return WorkoutSession::create([
                'user_id'        => $user->id,
                'gym_id'         => $user->gym_id,
                'started_at'     => now(),
                'progress'       => 0,
                'points_granted' => false,
            ]);
        });

        $isExisting = !$session->wasRecentlyCreated;

        return response()->json([
            'message'     => $isExisting
                ? 'Sessão de treino já ativa.'
                : 'Sessão de treino iniciada.',
            'session'     => $this->formatSession($session),
            'is_existing' => $isExisting,
        ], $isExisting ? 200 : 201);
    }

    /**
     * POST /api/workout/progress
     *
     * Updates the progress (0–100) of the active session.
     * If both conditions are met (elapsed time + progress >= thresholds)
     * and points were not yet granted, grants 10 points atomically.
     */
    public function updateProgress(Request $request, PointService $pointService)
    {
        $request->validate([
            'progress' => 'required|integer|between:0,100',
        ]);

        $user = $request->user();

        $session = WorkoutSession::where('user_id', $user->id)
            ->whereNull('finished_at')
            ->first();

        if (!$session) {
            return response()->json([
                'message' => 'Nenhuma sessão de treino ativa.',
            ], 404);
        }

        Log::info('workout.progress', [
            'user_id'    => $user->id,
            'session_id' => $session->id,
            'progress'   => $request->progress,
            'elapsed_s'  => (int) $session->started_at->diffInSeconds(now()),
        ]);

        $session->update(['progress' => $request->progress]);

        $pointsJustGranted = false;

        if (!$session->points_granted && $session->meetsPointsConditions()) {
            if (!WorkoutSession::hasGrantedPointsToday($user->id)) {
                $pointsJustGranted = $this->grantPoints($session, $user, $pointService);
            }
        }

        return response()->json([
            'message'             => $pointsJustGranted
                ? 'Progresso atualizado. Pontos liberados!'
                : 'Progresso atualizado.',
            'points_just_granted' => $pointsJustGranted,
            'session'             => $this->formatSession($session->fresh()),
        ]);
    }

    /**
     * POST /api/workout/finish
     *
     * Finishes the active session, computes progress from the sets data sent
     * by the app, grants points if conditions are met, and returns the streak.
     *
     * If called when there is no active session (e.g. double-tap), looks for a
     * session finished today and returns it with already_finished = true so the
     * app can navigate to the completion screen without showing an error.
     *
     * Body (optional):
     *   exercises_completed  – number of exercises the user fully completed
     *   exercises_total      – total exercises in the workout
     *   sets_completed       – total sets marked done (legacy, still accepted)
     *   sets_total           – total sets in workout   (legacy, still accepted)
     */
    public function finish(Request $request, PointService $pointService)
    {
        $request->validate([
            'exercises_completed' => 'nullable|integer|min:0',
            'exercises_total'     => 'nullable|integer|min:1',
            'sets_completed'      => 'nullable|integer|min:0',
            'sets_total'          => 'nullable|integer|min:1',
        ]);

        $user = $request->user();

        $session = WorkoutSession::where('user_id', $user->id)
            ->whereNull('finished_at')
            ->first();

        // ── No active session ─────────────────────────────────────────────────
        if (!$session) {
            // Check if the user already finished a session today
            $todaySession = WorkoutSession::where('user_id', $user->id)
                ->whereNotNull('finished_at')
                ->whereDate('started_at', now()->toDateString())
                ->latest('finished_at')
                ->first();

            if ($todaySession) {
                return response()->json([
                    'message'          => 'Treino já finalizado hoje.',
                    'already_finished' => true,
                    'points_just_granted' => false,
                    'streak'           => $this->calculateStreak($user->id),
                    'session'          => $this->formatSession($todaySession),
                ]);
            }

            return response()->json([
                'message' => 'Nenhuma sessão de treino ativa.',
            ], 404);
        }

        // ── Update progress from exercises data (preferred) or sets data ──────
        $progress = $session->progress; // keep existing if nothing sent

        if ($request->filled('exercises_completed') && $request->filled('exercises_total')) {
            $progress = (int) round(
                ($request->exercises_completed / $request->exercises_total) * 100
            );
        } elseif ($request->filled('sets_completed') && $request->filled('sets_total')) {
            $progress = (int) round(
                ($request->sets_completed / $request->sets_total) * 100
            );
        }

        $session->update(['progress' => $progress]);
        $session->refresh();

        // ── Grant points if conditions are met ────────────────────────────────
        $pointsJustGranted = false;

        if (!$session->points_granted && $session->meetsPointsConditions()) {
            if (!WorkoutSession::hasGrantedPointsToday($user->id)) {
                $pointsJustGranted = $this->grantPoints($session, $user, $pointService);
                $session->refresh();
            }
        }

        // ── Finish session ────────────────────────────────────────────────────
        $session->update(['finished_at' => now()]);

        return response()->json([
            'message'             => 'Sessão de treino finalizada.',
            'already_finished'    => false,
            'points_just_granted' => $pointsJustGranted,
            'streak'              => $this->calculateStreak($user->id),
            'session'             => $this->formatSession($session->fresh()),
        ]);
    }

    /**
     * GET /api/workout/status
     *
     * Returns the most recent session (active or finished) for the user.
     * Returns { session: null } if none exists.
     */
    public function status(Request $request)
    {
        $session = WorkoutSession::where('user_id', $request->user()->id)
            ->latest('started_at')
            ->first();

        return response()->json([
            'session' => $session ? $this->formatSession($session) : null,
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Calculates the current consecutive-day streak for the user based on
     * finished workout sessions (same logic as DashboardController).
     */
    private function calculateStreak(int $userId): int
    {
        $dates = WorkoutSession::where('user_id', $userId)
            ->whereNotNull('finished_at')
            ->orderBy('finished_at', 'desc')
            ->pluck('finished_at')
            ->map(fn($d) => $d->toDateString())
            ->unique()
            ->values()
            ->all();

        if (empty($dates)) {
            return 0;
        }

        $today    = now()->toDateString();
        $streak   = 0;
        $expected = in_array($today, $dates, true)
            ? now()->startOfDay()
            : now()->subDay()->startOfDay();

        foreach ($dates as $dateStr) {
            $date = \Carbon\Carbon::parse($dateStr)->startOfDay();
            if ($date->equalTo($expected)) {
                $streak++;
                $expected = $expected->subDay();
            } elseif ($date->lt($expected)) {
                break;
            }
        }

        return $streak;
    }

    /**
     * Grants 10 points inside a DB transaction with a pessimistic lock
     * to prevent race conditions (double-granting).
     *
     * Returns true if points were actually granted, false if already granted.
     */
    private function grantPoints(WorkoutSession $session, $user, PointService $pointService): bool
    {
        $granted = false;

        DB::transaction(function () use ($session, $user, $pointService, &$granted) {
            $locked = WorkoutSession::where('id', $session->id)
                ->lockForUpdate()
                ->first();

            if ($locked && !$locked->points_granted) {
                $locked->update([
                    'points_granted'    => true,
                    'points_granted_at' => now(),
                ]);

                $pointService->earnPoints($user, 10, 'Treino concluído');
                $granted = true;
            }
        });

        return $granted;
    }

    /**
     * Formats a WorkoutSession into the standard API response array.
     */
    private function formatSession(WorkoutSession $session): array
    {
        $endpoint     = $session->finished_at ?? now();
        $dailyGranted = WorkoutSession::hasGrantedPointsToday($session->user_id);

        return [
            'id'                           => $session->id,
            'started_at'                   => $session->started_at->toIso8601String(),
            'finished_at'                  => $session->finished_at?->toIso8601String(),
            'is_active'                    => $session->isActive(),
            'progress'                     => $session->progress,
            'elapsed_seconds'              => (int) $session->started_at->diffInSeconds($endpoint),
            'points_granted'               => $session->points_granted,
            'points_granted_at'            => $session->points_granted_at?->toIso8601String(),
            'meets_conditions'             => $session->meetsPointsConditions(),
            'can_earn_points'              => !$session->points_granted && $session->meetsPointsConditions(),
            'min_minutes'                  => (int) config('workout.min_minutes', 10),
            'min_progress'                 => (int) config('workout.min_progress', 70),
            'is_bonus_session'             => $dailyGranted && !$session->points_granted,
            'daily_points_already_granted' => $dailyGranted,
            'daily_points_limit'           => (int) config('workout.daily_points_limit', 10),
            'requirements'                 => [
                'min_minutes'  => config('workout.min_minutes'),
                'min_progress' => config('workout.min_progress'),
            ],
        ];
    }
}
