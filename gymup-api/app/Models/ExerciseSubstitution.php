<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ExerciseSubstitution extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'exercise_id',
        'substitute_exercise_id',
        'priority',
    ];

    protected $casts = [
        'priority' => 'integer',
    ];

    public function exercise(): BelongsTo
    {
        return $this->belongsTo(Exercise::class, 'exercise_id');
    }

    public function substitute(): BelongsTo
    {
        return $this->belongsTo(Exercise::class, 'substitute_exercise_id');
    }
}
