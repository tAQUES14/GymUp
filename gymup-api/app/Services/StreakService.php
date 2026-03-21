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
     * Read-only streak state. Uses lazy evaluation to detect missed training days.
     *
     * If the user has a training schedule, checks all days since last_workout_date
     * for missed training days and resets the streak if any are found.
     *
     * Also maintains weekly progress data (for the weekly progress bar UI).
     *
     * @return array{
     *   streak: int,
     *   best_streak: int,
     *   remaining_workouts_this_week: int,
     *   workouts_done_this_week: int,
     *   weekly_goal: int,
     *   week_goal_completed: bool
     * }
     */
    public function getStreakState(User $user): array
    {
        $user->refresh();

        // Lazily detect missed training days and break streak if needed
        if ($this->hasTrainingSchedule($user)) {
            $this->checkAndBreakStreakIfNeeded($user, now()->toDateString());
            $user->refresh();
        }

        // Weekly rotation for weekly progress display
        $this->refreshWeekIfNeeded($user);
        $user->refresh();

        // Lazy-heal: fix week_goal_completed if workouts already meet goal
        if (! $user->week_goal_completed) {
            $effectiveGoal = (int) ($user->current_week_goal ?? $this->getUserWeeklyGoal($user->id));
            $daysThisWeek  = $this->countTrainingDaysThisWeek($user);

            if ($daysThisWeek >= $effectiveGoal) {
                $user->week_goal_completed = true;
                $user->save();
                $user->refresh();
            }
        }

        return $this->buildState($user);
    }

    /**
     * Called after a valid workout is granted points.
     *
     * Daily streak logic:
     *   - If user has a training schedule AND today is a training day:
     *       * Break streak if any training days were missed since last_workout_date
     *       * Increment current_streak
     *       * Update best_streak
     *       * Idempotent: only counts once per day
     *   - If user has no training schedule: streak is not modified
     *
     * Also handles weekly goal tracking (for bonus points and UI display).
     *
     * @return array{
     *   streak: int,
     *   best_streak: int,
     *   remaining_workouts_this_week: int,
     *   workouts_done_this_week: int,
     *   weekly_goal: int,
     *   week_goal_completed: bool,
     *   streak_just_increased: bool,
     *   weekly_goal_just_completed: bool
     * }
     */
    public function processWorkoutForDailyStreak(User $user): array
    {
        $user->refresh();
        $today = now()->toDateString();
        $streakJustIncreased = false;

        if ($this->hasTrainingSchedule($user)) {
            $todayIsTrainingDay = $this->isTrainingDay($user, now()->dayOfWeek);

            $lastWorkoutDateStr = $user->last_workout_date instanceof \Carbon\Carbon
                ? $user->last_workout_date->toDateString()
                : (string) ($user->last_workout_date ?? '');

            if ($todayIsTrainingDay && $lastWorkoutDateStr !== $today) {
                // Detect and apply any streak breaks from missed days
                $this->checkAndBreakStreakIfNeeded($user, $today);
                $user->refresh();

                $newStreak = ((int) $user->current_streak) + 1;

                $user->current_streak    = $newStreak;
                $user->best_streak       = max($newStreak, (int) $user->best_streak);
                $user->last_workout_date = $today;
                $user->save();
                $user->refresh();

                $streakJustIncreased = true;
            }
        }

        // Weekly tracking for progress display and bonus trigger
        $this->refreshWeekIfNeeded($user);
        $user->refresh();

        $weeklyJustCompleted = false;

        if (! $user->week_goal_completed) {
            $effectiveGoal = (int) ($user->current_week_goal ?? $this->getUserWeeklyGoal($user->id));
            $daysThisWeek  = $this->countTrainingDaysThisWeek($user);

            if ($daysThisWeek >= $effectiveGoal) {
                $user->week_goal_completed = true;
                $user->save();
                $user->refresh();
                $weeklyJustCompleted = true;
            }
        }

        return array_merge(
            $this->buildState($user),
            [
                'streak_just_increased'      => $streakJustIncreased,
                'weekly_goal_just_completed' => $weeklyJustCompleted,
            ]
        );
    }

    /**
     * Backward-compatible alias used by WorkoutController.
     * Delegates to processWorkoutForDailyStreak.
     */
    public function processWorkoutForWeeklyStreak(User $user): array
    {
        return $this->processWorkoutForDailyStreak($user);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Daily streak core logic
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Scans every day between last_workout_date (exclusive) and $upToDate (exclusive).
     * If any of those days is a training day with no completed workout,
     * resets current_streak to 0 immediately and returns.
     *
     * If last_schedule_change is set and is AFTER last_workout_date + 1 day,
     * only checks from last_schedule_change forward. This prevents a schedule
     * change from retroactively breaking a streak for days before the change.
     */
    private function checkAndBreakStreakIfNeeded(User $user, string $upToDate): void
    {
        if (! $user->last_workout_date) {
            return; // No history yet — nothing to break
        }

        $lastDate  = Carbon::parse($user->last_workout_date);
        $upTo      = Carbon::parse($upToDate);
        $startFrom = $lastDate->copy()->addDay();

        // Do not reinterpret days before the schedule was last changed
        if ($user->last_schedule_change) {
            $scheduleChange = Carbon::parse($user->last_schedule_change);
            if ($scheduleChange->gt($startFrom)) {
                $startFrom = $scheduleChange->copy();
            }
        }

        $current = $startFrom->copy();

        while ($current->lt($upTo)) {
            if ($this->isTrainingDay($user, $current->dayOfWeek)) {
                $done = WorkoutSession::where('user_id', $user->id)
                    ->whereDate('finished_at', $current->toDateString())
                    ->where('points_granted', true)
                    ->exists();

                if (! $done) {
                    $user->current_streak = 0;
                    $user->save();
                    return;
                }
            }

            $current->addDay();
        }
    }

    private function isTrainingDay(User $user, int $dayOfWeek): bool
    {
        return $user->trainingSchedules()
            ->where('day_of_week', $dayOfWeek)
            ->exists();
    }

    private function hasTrainingSchedule(User $user): bool
    {
        return $user->trainingSchedules()->exists();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Weekly rotation (for weekly progress display only)
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Resets week_goal_completed and refreshes current_week_start / current_week_goal
     * when a new calendar week has started (Monday-based).
     *
     * Does NOT modify the daily streak or weekly_streak anymore.
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

        if ($storedStart >= $thisWeekStart) {
            return; // Still the same week
        }

        // New week started — reset weekly display tracking
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
            'streak'                       => (int) ($user->current_streak ?? 0),
            'best_streak'                  => (int) ($user->best_streak ?? 0),
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
