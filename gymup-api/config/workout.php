<?php

return [



    'min_minutes'           => (int) env('WORKOUT_MIN_MINUTES', 10),
    'max_minutes'           => (int) env('WORKOUT_MAX_MINUTES', 360),
    'min_progress_valid'    => (int) env('WORKOUT_MIN_PROGRESS_VALID', 75),
    'min_progress_partial'  => (int) env('WORKOUT_MIN_PROGRESS_PARTIAL', 70),
    'session_timeout_hours' => (int) env('WORKOUT_SESSION_TIMEOUT_HOURS', 4),
    'daily_points'          => (int) env('WORKOUT_DAILY_POINTS', 10),
    'pr_bonus'              => (int) env('WORKOUT_PR_BONUS', 5),
    'streak_bonus_milestones' => [
        3  => (int) env('WORKOUT_STREAK_BONUS_3', 10),
        7  => (int) env('WORKOUT_STREAK_BONUS_7', 30),
        14 => (int) env('WORKOUT_STREAK_BONUS_14', 70),
        30 => (int) env('WORKOUT_STREAK_BONUS_30', 150),
    ],

];
