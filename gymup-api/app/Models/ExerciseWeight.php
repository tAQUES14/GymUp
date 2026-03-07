<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ExerciseWeight extends Model
{
    protected $fillable = [
        'user_id',
        'gym_id',
        'exercise_id',
        'set_number',
        'weight',
        'reps',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'weight'     => 'decimal:2',
        'reps'       => 'integer',
        'set_number' => 'integer',
    ];
}