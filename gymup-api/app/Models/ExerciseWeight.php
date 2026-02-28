<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ExerciseWeight extends Model
{
    protected $fillable = [
        'user_id',
        'exercise_id',
        'weight',
        'reps',
        'note',
    ];
}