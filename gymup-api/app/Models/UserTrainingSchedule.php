<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserTrainingSchedule extends Model
{
    protected $fillable = ['user_id', 'gym_id', 'day_of_week'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
