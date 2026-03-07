<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Workout Session Settings
    |--------------------------------------------------------------------------
    |
    | min_minutes          — Minimum session duration (minutes) before points are granted.
    |                        Set WORKOUT_MIN_MINUTES=1 in .env for quick testing.
    |
    | min_progress_valid   — Minimum completion % for a fully valid workout (75%).
    | min_progress_partial — Minimum completion % for a partial workout needing confirmation (70%).
    | daily_points         — Points awarded per valid workout.
    |
    */

    'min_minutes'          => (int) env('WORKOUT_MIN_MINUTES', 10),
    'min_progress_valid'   => (int) env('WORKOUT_MIN_PROGRESS_VALID', 75),
    'min_progress_partial' => (int) env('WORKOUT_MIN_PROGRESS_PARTIAL', 70),
    'session_timeout_hours' => (int) env('WORKOUT_SESSION_TIMEOUT_HOURS', 4),
    'daily_points'         => (int) env('WORKOUT_DAILY_POINTS', 10),
    'streak_bonus'         => (int) env('WORKOUT_STREAK_BONUS', 5),
    'pr_bonus'             => (int) env('WORKOUT_PR_BONUS', 5),

];
