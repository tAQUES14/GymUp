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
        'checkin_gym_id',
        'started_at',
        'finished_at',
        'progress',
        'points_granted',
        'points_granted_at',
        'is_valid',
        'counts_for_points',
        'counts_for_streak',
    ];

    protected $casts = [
        'started_at'        => 'datetime',
        'finished_at'       => 'datetime',
        'points_granted_at' => 'datetime',
        'points_granted'    => 'boolean',
        'progress'          => 'integer',
        'is_valid'          => 'boolean',
        'counts_for_points' => 'boolean',
        'counts_for_streak' => 'boolean',
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

    public function workoutSets()
    {
        return $this->hasMany(WorkoutSet::class, 'workout_session_id');
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Domain helpers
    // ──────────────────────────────────────────────────────────────────────────

    /** Returns true while the session has not been finished. */
    public function isActive(): bool
    {
        return $this->finished_at === null;
    }

    /**
     * Scope: sessions that are still open AND within the configured timeout window.
     * Use this instead of bare whereNull('finished_at') so stale sessions are ignored.
     */
    public function scopeActiveSession($query)
    {
        $hours = (int) config('workout.session_timeout_hours', 4);

        return $query
            ->whereNull('finished_at')
            ->where('started_at', '>=', now()->subHours($hours));
    }

    /**
     * Elapsed time in minutes for this session.
     *
     * Rules:
     *   - No started_at → 0
     *   - Finished session → finished_at - started_at
     *   - Active session   → now() - started_at
     *   - Negative result  → 0 (clock skew guard)
     */
    public function elapsedMinutes(): float
    {
        if (!$this->started_at) {
            return 0;
        }

        $endpoint = $this->finished_at ?? now();
        $minutes  = $this->started_at->diffInMinutes($endpoint);

        return max(0, $minutes);
    }

    /**
     * Returns true when ALL conditions required to earn points are met:
     *   - elapsed time >= config('workout.min_minutes')
     *   - elapsed time <= config('workout.max_minutes', 360)  [stale session guard]
     *   - progress     >= config('workout.min_progress_valid')
     */
    public function meetsPointsConditions(): bool
    {
        $elapsed = $this->elapsedMinutes();

        return $elapsed >= config('workout.min_minutes')
            && $elapsed <= config('workout.max_minutes', 360)
            && $this->progress >= config('workout.min_progress_valid', 75);
    }

    /**
     * Returns true when the user has already earned points today.
     * Uses finished_at (consistent with StreakService) so sessions that cross
     * midnight are attributed to the day they were actually completed.
     * Accepts an optional date string (Y-m-d) to override "today".
     */
    public static function hasGrantedPointsToday($userId, $date = null): bool
    {
        $date = $date ?? now()->toDateString();

        return static::where('user_id', $userId)
            ->where('points_granted', true)
            ->whereDate('finished_at', $date)
            ->exists();
    }
}
