<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkoutPlanDay extends Model
{
    protected $fillable = ['plan_id', 'day_of_week', 'name', 'rest_day'];

    protected $casts = [
        'rest_day'    => 'boolean',
        'day_of_week' => 'integer',
    ];

    public function plan()
    {
        return $this->belongsTo(WorkoutPlan::class, 'plan_id');
    }

    public function exercises()
    {
        return $this->hasMany(WorkoutExercise::class, 'plan_day_id')->orderBy('exercise_order');
    }
}
