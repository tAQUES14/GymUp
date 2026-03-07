<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChallengeParticipant extends Model
{
    protected $fillable = [
        'challenge_id',
        'user_id',
        'gym_id',
        'total_challenge_points',
        'workouts_this_challenge',
        'goal_completed',
        'goal_completed_at',
        'reward_granted',
    ];

    protected $casts = [
        'goal_completed'    => 'boolean',
        'goal_completed_at' => 'datetime',
        'reward_granted'    => 'boolean',
    ];

    public function challenge()
    {
        return $this->belongsTo(GymChallenge::class, 'challenge_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
