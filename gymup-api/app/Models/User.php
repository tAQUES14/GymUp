<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'gym_id',
        'role',
        'points_balance',
        'height',
        'weight',
        'birth_date',
        'weekly_streak',
        'week_goal_completed',
        'current_week_start',
        'current_week_goal',
        'current_streak',
        'best_streak',
        'last_workout_date',
        'last_schedule_change',
    ];

    protected $casts = [
        'week_goal_completed' => 'boolean',
        'current_week_start'  => 'date',
        'last_workout_date'    => 'date',
        'last_schedule_change' => 'date',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    // ── Role helpers ──────────────────────────────────────────────────────────

    public function isSuperAdmin(): bool
    {
        return $this->role === 'super_admin';
    }

    public function isGymAdmin(): bool
    {
        return $this->role === 'gym_admin';
    }

    public function isTrainer(): bool
    {
        return $this->role === 'trainer';
    }

    public function isUser(): bool
    {
        return $this->role === 'user';
    }

    /** Retorna true para qualquer role com acesso ao painel administrativo. */
    public function canAccessAdminPanel(): bool
    {
        return in_array($this->role, ['super_admin', 'gym_admin', 'trainer'], true);
    }

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }

    public function checkins()
    {
        return $this->hasMany(Checkin::class);
    }

    public function pointTransactions()
    {
        return $this->hasMany(PointTransaction::class);
    }

    public function redemptions()
    {
        return $this->hasMany(Redemption::class);
    }

    public function workoutSessions()
    {
        return $this->hasMany(WorkoutSession::class);
    }

    public function goals()
    {
        return $this->hasMany(UserGoal::class);
    }

    public function trainingSchedules()
    {
        return $this->hasMany(UserTrainingSchedule::class);
    }

    // Named userNotifications to avoid collision with Laravel's Notifiable::notifications()
    public function userNotifications()
    {
        return $this->hasMany(UserNotification::class);
    }
}