<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ExerciseWeight extends Model
{
    protected $fillable = [
        'user_id',
        'exercise_id',
        'set_number',
        'weight',
        'reps',
    ];

    protected $casts = [
        'weight' => 'float',
        'reps' => 'integer',
        'set_number' => 'integer',
    ];
}
