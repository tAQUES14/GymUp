<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserExerciseOverride extends Model
{
    protected $fillable = [
        'exercise_id',
        'user_id',
        'custom_video_url',
        'custom_description',
        'custom_execution_steps',
        'custom_tips',
    ];

    protected $casts = [
        'custom_execution_steps' => 'array',
        'custom_tips'            => 'array',
    ];

    public function exercise(): BelongsTo
    {
        return $this->belongsTo(Exercise::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
