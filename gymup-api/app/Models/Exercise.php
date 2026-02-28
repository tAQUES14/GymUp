<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Exercise extends Model
{
    protected $fillable = [
        'name',
        'muscle_group',
        'default_rest',
    ];

    public function workouts()
    {
        return $this->belongsToMany(CustomWorkout::class)
            ->withPivot(['sets', 'reps', 'rest'])
            ->withTimestamps();
    }
}