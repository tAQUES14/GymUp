<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WorkoutSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'gym_id',
        'started_at',
        'finished_at',
        'progress',
        'points_granted',
        'points_granted_at',
    ];

    protected $casts = [
        'started_at'        => 'datetime',
        'finished_at'       => 'datetime',
        'points_granted_at' => 'datetime',
        'points_granted'    => 'boolean',
        'progress'          => 'integer',
    ];

    // ──────────────────────────────────────────────────────────────────────────
    // Relationships
    // ──────────────────────────────────────────────────────────────────────────

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Domain helpers
    // ──────────────────────────────────────────────────────────────────────────

    /** Returns true while the session has not been finished. */
    public function isActive(): bool
    {
        return $this->finished_at === null;
    }

    /** Elapsed time in minutes since the session started (uses testable now()). */
    public function elapsedMinutes(): float
    {
        return $this->started_at->diffInMinutes(now());
    }

    /**
     * Returns true when BOTH conditions required to earn points are met:
     *   - elapsed time >= config('workout.min_minutes')
     *   - progress    >= config('workout.min_progress')
     */
    public function meetsPointsConditions(): bool
    {
        return $this->elapsedMinutes() >= config('workout.min_minutes')
            && $this->progress >= config('workout.min_progress');
    }
}
