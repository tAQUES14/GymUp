<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkoutPlan extends Model
{
    protected $fillable = ['gym_id', 'name', 'description', 'between_exercise_rest_seconds', 'active_week_days', 'created_by'];

    protected $casts = [
        'active_week_days' => 'array',
    ];

    public function days()
    {
        return $this->hasMany(WorkoutPlanDay::class, 'plan_id')->orderBy('day_of_week');
    }

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function userWorkoutPlans()
    {
        return $this->hasMany(UserWorkoutPlan::class, 'plan_id');
    }
}
