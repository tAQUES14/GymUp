<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkoutHistory extends Model
{
    protected $fillable = [
        'user_id',
        'workout_id',
        'workout_name',
        'duration_minutes',
        'sets_completed',
        'sets_total',
        'points_earned',
        'had_checkin'
    ];
}