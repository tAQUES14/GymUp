<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Models\WorkoutSession;
use App\Services\WorkoutFinishService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WorkoutController extends Controller
{
    /**
     * POST /api/workout/start
     *
     * Starts a new workout session for the authenticated user.
     * Idempotent: if an active session already exists, returns it.
     */
    public function start(Request $request)
    {
        $user = $request->user();

        $timeoutHours = (int) config('workout.session_timeout_hours', 4);

        $session = DB::transaction(function () use ($user, $timeoutHours) {
            $active = WorkoutSession::where('user_id', $user->id)
                ->whereNull('finished_at')
                ->lockForUpdate()
                ->first();

            if ($active) {
                // Auto-expire sessions older than the configured timeout
                if ($active->started_at->diffInHours(now()) >= $timeoutHours) {
                    $active->update(['finished_at' => now()]);
                } else {
                    return $active;
                }
            }

            $checkinGymId = Checkin::where('user_id', $user->id)
                ->where('checkin_date', now()->toDateString())
                ->value('gym_id');

            return WorkoutSession::create([
                'user_id'        => $user->id,
                'gym_id'         => $user->gym_id,
                'checkin_gym_id' => $checkinGymId,
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
     */
    public function updateProgress(Request $request)
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

        return response()->json([
            'message' => 'Progresso atualizado.',
            'session' => $this->formatSession($session->fresh()),
        ]);
    }

    /**
     * POST /api/workout/finish
     * POST /api/workout-sessions/{id}/finish  (alias)
     *
     * Finishes the active workout session. All domain logic (validation,
     * points, streak, challenges) is delegated to WorkoutFinishService.
     * This method only handles HTTP concerns.
     */
    public function finish(
        Request              $request,
        WorkoutFinishService $finishService,
        ?int                 $id = null
    ) {
        $request->validate([
            'completion_percent' => 'nullable|integer|between:0,100',
            'duration_seconds'   => 'nullable|integer|min:0',
            'confirm_partial'    => 'nullable|boolean',
        ]);

        $user = $request->user();

        $query = WorkoutSession::where('user_id', $user->id)->whereNull('finished_at');
        if ($id !== null) {
            $query->where('id', $id);
        }

        $session = $query->first();
        if (!$session) {
            return response()->json(['message' => 'Nenhuma sessão de treino ativa.'], 404);
        }

        // Resolve inputs, falling back to session/elapsed values when not provided
        $completionPercent = $request->input('completion_percent', $session->progress);
        $maxSeconds        = (int) config('workout.max_minutes', 360) * 60;
        $rawDuration       = $request->input('duration_seconds', (int) $session->started_at->diffInSeconds(now()));
        $durationSeconds   = max(0, min((int) $rawDuration, $maxSeconds));
        $confirmPartial    = (bool) $request->input('confirm_partial', false);

        $hasCheckinToday = Checkin::where('user_id', $user->id)
            ->where('checkin_date', now()->toDateString())
            ->exists();

        // Save the final progress before validation so the DB reflects what the user actually did
        $session->update(['progress' => $completionPercent]);

        // Delegate all domain logic to the service
        $result = $finishService->handle(
            $session,
            $user,
            $completionPercent,
            $durationSeconds,
            $confirmPartial,
            $hasCheckinToday,
        );

        return response()->json(array_merge($result, [
            'total_points'      => (int) $user->fresh()->points_balance,
            'checkin_validated' => $hasCheckinToday,
            'session'           => $this->formatSession($result['session']),
        ]));
    }

    /**
     * GET /api/workout/status
     *
     * Returns only the currently active (unfinished) session that is still within
     * the configured timeout window. Sessions older than the timeout are expired
     * on the spot so they never reach the client as "resumable".
     */
    public function status(Request $request)
    {
        $userId       = $request->user()->id;
        $timeoutHours = (int) config('workout.session_timeout_hours', 4);

        // Auto-expire any stale open sessions before checking for an active one.
        WorkoutSession::where('user_id', $userId)
            ->whereNull('finished_at')
            ->where('started_at', '<', now()->subHours($timeoutHours))
            ->update(['finished_at' => now()]);

        $session = WorkoutSession::activeSession()
            ->where('user_id', $userId)
            ->latest('started_at')
            ->first();

        return response()->json([
            'session' => $session ? $this->formatSession($session) : null,
        ]);
    }

    /**
     * Formats a WorkoutSession into the standard API response array.
     */
    private function formatSession(WorkoutSession $session): array
    {
        $endpoint     = $session->finished_at ?? now();
        $dailyGranted = WorkoutSession::hasGrantedPointsToday($session->user_id);

        $maxSeconds     = (int) config('workout.max_minutes', 360) * 60;
        $rawElapsed     = (int) $session->started_at->diffInSeconds($endpoint);
        $elapsedSeconds = max(0, min($rawElapsed, $maxSeconds));

        return [
            'id'                           => $session->id,
            'started_at'                   => $session->started_at->toIso8601String(),
            'finished_at'                  => $session->finished_at?->toIso8601String(),
            'is_active'                    => $session->isActive(),
            'progress'                     => $session->progress,
            'elapsed_seconds'              => $elapsedSeconds,
            'points_granted'               => $session->points_granted,
            'points_granted_at'            => $session->points_granted_at?->toIso8601String(),
            'is_valid'                     => $session->is_valid,
            'counts_for_points'            => $session->counts_for_points,
            'counts_for_streak'            => $session->counts_for_streak,
            'meets_conditions'             => $session->meetsPointsConditions(),
            'can_earn_points'              => !$session->points_granted && !$dailyGranted,
            'min_minutes'                  => (int) config('workout.min_minutes', 10),
            'daily_points_already_granted' => $dailyGranted,
            'requirements'                 => [
                'min_minutes'          => (int) config('workout.min_minutes'),
                'min_progress_valid'   => (int) config('workout.min_progress_valid'),
                'min_progress_partial' => (int) config('workout.min_progress_partial'),
            ],
        ];
    }
}
