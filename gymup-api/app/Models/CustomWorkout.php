<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomWorkout extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'description',
        'level',
        'duration',
        'is_generated',
    ];

    protected $casts = [
        'is_generated' => 'boolean',
    ];

    public function exercises()
    {
        return $this->belongsToMany(Exercise::class)
            ->withPivot(['sets', 'reps', 'rest'])
            ->withTimestamps();
    }
}