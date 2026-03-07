<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChallengeWeeklyRanking extends Model
{
    protected $fillable = [
        'challenge_id',
        'user_id',
        'week_start',
        'workouts_count',
        'position',
        'points_awarded',
        'finalized',
    ];

    protected $casts = [
        'week_start' => 'datetime:Y-m-d',
        'finalized'  => 'boolean',
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
