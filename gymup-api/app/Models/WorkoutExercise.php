<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkoutExercise extends Model
{
    protected $fillable = [
        'plan_day_id',
        'exercise_id',
        'sets',
        'reps',
        'rest_seconds',
        'exercise_order',
        'duration_minutes',
        'distance_km',
        'technique',
        'group_id',
        'rounds',
        'drops',
    ];

    protected $casts = [
        'sets'             => 'integer',
        'rest_seconds'     => 'integer',
        'exercise_order'   => 'integer',
        'duration_minutes' => 'integer',
        'distance_km'      => 'float',
        'group_id'         => 'integer',
        'rounds'           => 'integer',
        'drops'            => 'integer',
    ];

    public function planDay()
    {
        return $this->belongsTo(WorkoutPlanDay::class, 'plan_day_id');
    }

    public function exercise()
    {
        return $this->belongsTo(Exercise::class);
    }
}
