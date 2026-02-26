<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WorkoutSession;
use App\Services\PointService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WorkoutController extends Controller
{
    /**
     * POST /api/workout/start
     *
     * Starts a new workout session for the authenticated user.
     * Returns 409 if an active session already exists.
     */
    public function start(Request $request)
    {
        $user = $request->user();

        $activeSession = WorkoutSession::where('user_id', $user->id)
            ->whereNull('finished_at')
            ->first();

        if ($activeSession) {
            return response()->json([
                'message' => 'Você já tem uma sessão de treino ativa.',
                'session' => $this->formatSession($activeSession),
            ], 409);
        }

        $session = WorkoutSession::create([
            'user_id'        => $user->id,
            'gym_id'         => $user->gym_id,
            'started_at'     => now(),
            'progress'       => 0,
            'points_granted' => false,
        ]);

        return response()->json([
            'message' => 'Sessão de treino iniciada.',
            'session' => $this->formatSession($session),
        ], 201);
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

        $session->update(['progress' => $request->progress]);

        $pointsJustGranted = false;

        if (!$session->points_granted && $session->meetsPointsConditions()) {
            $pointsJustGranted = $this->grantPoints($session, $user, $pointService);
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
     * Finishes the active session and marks finished_at.
     * If conditions are met and points were not yet granted, grants them first.
     * Returns 404 if no active session exists.
     */
    public function finish(Request $request, PointService $pointService)
    {
        $user = $request->user();

        $session = WorkoutSession::where('user_id', $user->id)
            ->whereNull('finished_at')
            ->first();

        if (!$session) {
            return response()->json([
                'message' => 'Nenhuma sessão de treino ativa.',
            ], 404);
        }

        $pointsJustGranted = false;

        if (!$session->points_granted && $session->meetsPointsConditions()) {
            $pointsJustGranted = $this->grantPoints($session, $user, $pointService);
            $session->refresh();
        }

        $session->update(['finished_at' => now()]);

        return response()->json([
            'message'             => 'Sessão de treino finalizada.',
            'points_just_granted' => $pointsJustGranted,
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
        $endpoint = $session->finished_at ?? now();

        return [
            'id'                => $session->id,
            'started_at'        => $session->started_at->toIso8601String(),
            'finished_at'       => $session->finished_at?->toIso8601String(),
            'is_active'         => $session->isActive(),
            'progress'          => $session->progress,
            'elapsed_seconds'   => (int) $session->started_at->diffInSeconds($endpoint),
            'points_granted'    => $session->points_granted,
            'points_granted_at' => $session->points_granted_at?->toIso8601String(),
            'can_earn_points'   => !$session->points_granted && $session->meetsPointsConditions(),
            'requirements'      => [
                'min_minutes'  => config('workout.min_minutes'),
                'min_progress' => config('workout.min_progress'),
            ],
        ];
    }
}
