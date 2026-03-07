<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserGoal extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'goal_type',
        'gender',
        'start_weight',
        'target_weight',
        'height',
        'age',
        'activity_level',
        'target_months',
        'estimated_daily_calorie_deficit',
        'estimated_workouts_per_week',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
