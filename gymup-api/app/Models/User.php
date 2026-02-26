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
        'birth_date'
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

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
}