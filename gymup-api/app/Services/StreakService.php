<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserGoal;
use App\Models\WorkoutSession;
use Carbon\Carbon;

class StreakService
{
    // ──────────────────────────────────────────────────────────────────────────
    // Public API
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Read-only streak state. Triggers week rotation if needed.
     * Called from DashboardController.
     *
     * @return array{
     *   streak: int,
     *   remaining_workouts_this_week: int,
     *   workouts_done_this_week: int,
     *   weekly_goal: int,
     *   week_goal_completed: bool
     * }
     */
    public function getStreakState(User $user): array
    {
        $this->refreshWeekIfNeeded($user);
        $user->refresh();

        // Lazy-heal: the goal may have been reached without processWorkoutForWeeklyStreak
        // being called (e.g. workouts completed before the weekly streak system was deployed,
        // or a race condition where the session was already finished). If the training-day
        // count already meets the weekly goal but the flag was never set, fix it now so the
        // streak is never stuck at 0 after the goal is met.
        if (! $user->week_goal_completed) {
            $effectiveGoal = (int) ($user->current_week_goal ?? $this->getUserWeeklyGoal($user->id));
            $daysThisWeek  = $this->countTrainingDaysThisWeek($user);

            if ($daysThisWeek >= $effectiveGoal) {
                $user->week_goal_completed = true;
                $user->weekly_streak       = ((int) ($user->weekly_streak ?? 0)) + 1;
                $user->save();
                $user->refresh();
            }
        }

        return $this->buildState($user);
    }

    /**
     * Called after a valid workout is granted points.
     *
     * Checks if the weekly goal was just met for the first time this week.
     * If yes:
     *   - Sets week_goal_completed = true
     *   - Increments weekly_streak immediately
     *   - Returns weekly_goal_just_completed = true
     *
     * The streak increment is idempotent within the same week because
     * week_goal_completed prevents double-counting.
     *
     * @return array{
     *   streak: int,
     *   remaining_workouts_this_week: int,
     *   workouts_done_this_week: int,
     *   weekly_goal: int,
     *   week_goal_completed: bool,
     *   weekly_goal_just_completed: bool
     * }
     */
    public function processWorkoutForWeeklyStreak(User $user): array
    {
        $this->refreshWeekIfNeeded($user);
        $user->refresh();

        $justCompleted = false;

        // Only check if goal not yet completed this week
        if (! $user->week_goal_completed) {
            $effectiveGoal = (int) ($user->current_week_goal ?? $this->getUserWeeklyGoal($user->id));
            $daysThisWeek  = $this->countTrainingDaysThisWeek($user);

            if ($daysThisWeek >= $effectiveGoal) {
                $user->week_goal_completed = true;
                $user->weekly_streak       = ((int) ($user->weekly_streak ?? 0)) + 1;
                $user->save();
                $user->refresh();
                $justCompleted = true;
            }
        }

        return array_merge(
            $this->buildState($user),
            ['weekly_goal_just_completed' => $justCompleted]
        );
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Week rotation (lazy — triggered on any request)
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Detects if the calendar week has changed since last tracking.
     *
     * Rules:
     *   - First call ever: initialize week fields, do not alter streak.
     *   - New week detected AND week_goal_completed == false:
     *       previous week ended without meeting the goal → streak resets to 0.
     *   - New week detected AND week_goal_completed == true:
     *       previous week was successful → preserve current streak value.
     *   - Resets week_goal_completed and updates current_week_start / current_week_goal.
     *
     * Idempotent: no-op if the current week hasn't changed.
     */
    private function refreshWeekIfNeeded(User $user): void
    {
        $thisWeekStart = Carbon::now()->startOfWeek(Carbon::MONDAY)->toDateString();

        // First-time initialization
        if ($user->current_week_start === null) {
            $user->current_week_start = $thisWeekStart;
            $user->current_week_goal  = $this->getUserWeeklyGoal($user->id);
            $user->save();
            return;
        }

        $storedStart = $user->current_week_start instanceof Carbon
            ? $user->current_week_start->toDateString()
            : (string) $user->current_week_start;

        // Nothing to do — still in the same week
        if ($storedStart >= $thisWeekStart) {
            return;
        }

        // A new week has started
        if (! $user->week_goal_completed) {
            // Previous week ended without meeting the goal → break streak
            $user->weekly_streak = 0;
        }

        // Reset for the new week (snapshot the current goal at week start)
        $user->week_goal_completed = false;
        $user->current_week_start  = $thisWeekStart;
        $user->current_week_goal   = $this->getUserWeeklyGoal($user->id);
        $user->save();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────────────────

    private function buildState(User $user): array
    {
        $effectiveGoal = (int) ($user->current_week_goal ?? $this->getUserWeeklyGoal($user->id));
        $daysThisWeek  = $this->countTrainingDaysThisWeek($user);
        $remaining     = max(0, $effectiveGoal - $daysThisWeek);

        return [
            'streak'                       => (int) ($user->weekly_streak ?? 0),
            'remaining_workouts_this_week' => $remaining,
            'workouts_done_this_week'      => $daysThisWeek,
            'weekly_goal'                  => $effectiveGoal,
            'week_goal_completed'          => (bool) $user->week_goal_completed,
        ];
    }

    /**
     * Counts unique training days with points_granted = true in the current week.
     */
    private function countTrainingDaysThisWeek(User $user): int
    {
        $weekStart = Carbon::parse(
            $user->current_week_start
                ?? Carbon::now()->startOfWeek(Carbon::MONDAY)->toDateString()
        );
        $weekEnd = $weekStart->copy()->endOfWeek(Carbon::SUNDAY);

        return WorkoutSession::where('user_id', $user->id)
            ->where('points_granted', true)
            ->whereBetween('finished_at', [$weekStart, $weekEnd])
            ->get(['finished_at'])
            ->map(fn ($s) => $s->finished_at->toDateString())
            ->unique()
            ->count();
    }

    private function getUserWeeklyGoal(int $userId): int
    {
        return (int) (UserGoal::where('user_id', $userId)
            ->latest()
            ->value('estimated_workouts_per_week') ?? 3);
    }
}
