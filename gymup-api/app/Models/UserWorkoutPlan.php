<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserWorkoutPlan extends Model
{
    protected $fillable = ['user_id', 'plan_id', 'gym_id', 'current_day_index', 'started_at'];

    protected $casts = [
        'started_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function plan()
    {
        return $this->belongsTo(WorkoutPlan::class, 'plan_id');
    }
}
