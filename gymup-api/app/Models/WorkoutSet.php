<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WorkoutSet extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'workout_session_id',
        'exercise_id',
        'set_number',
        'weight',
        'reps',
    ];

    protected $casts = [
        'set_number' => 'integer',
        'weight'     => 'float',
        'reps'       => 'integer',
    ];

    public function session(): BelongsTo
    {
        return $this->belongsTo(WorkoutSession::class, 'workout_session_id');
    }

    public function exercise(): BelongsTo
    {
        return $this->belongsTo(Exercise::class);
    }
}
