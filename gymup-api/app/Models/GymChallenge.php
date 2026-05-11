<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GymChallenge extends Model
{
    use HasFactory;

    protected $fillable = [
        'gym_id',
        'type',
        'scope',
        'name',
        'description',
        'starts_at',
        'ends_at',
        'status',
        'reward_type',
        'reward_description',
        'min_weekly_workouts',
        'max_weekly_workouts',
        'weekly_points_config',
        'goal_workouts',
        'reward_points',
    ];

    protected $casts = [
        'starts_at'            => 'datetime:Y-m-d',
        'ends_at'              => 'datetime:Y-m-d',
        'weekly_points_config' => 'array',
    ];

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }

    public function participants()
    {
        return $this->hasMany(ChallengeParticipant::class, 'challenge_id');
    }

    public function weeklyRankings()
    {
        return $this->hasMany(ChallengeWeeklyRanking::class, 'challenge_id');
    }

    public function isCompetitive(): bool
    {
        return $this->type === 'competitive';
    }

    public function isSimple(): bool
    {
        return $this->type === 'simple';
    }

    public function isPersonal(): bool
    {
        return $this->scope === 'personal';
    }

    public function isCommunity(): bool
    {
        return $this->scope !== 'personal';
    }

    /** True se o desafio está ativo e dentro do período configurado. */
    public function isRunning(): bool
    {
        $today = now()->toDateString();

        return $this->status === 'active'
            && $today >= $this->starts_at->toDateString()
            && $today <= $this->ends_at->toDateString();
    }
}
