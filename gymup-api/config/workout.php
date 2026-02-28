<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Workout Session Settings
    |--------------------------------------------------------------------------
    |
    | min_minutes  — Minimum session duration before points are granted.
    |                Set WORKOUT_MIN_MINUTES=1 in .env for quick testing.
    |
    | min_progress — Minimum progress percentage required to earn points.
    |                Set WORKOUT_MIN_PROGRESS=70 in .env to override.
    |
    */

    'min_minutes'  => (int) env('WORKOUT_MIN_MINUTES', 10),
    'min_progress'       => (int) env('WORKOUT_MIN_PROGRESS', 70),
    'daily_points_limit' => (int) env('WORKOUT_DAILY_POINTS', 10),

];
