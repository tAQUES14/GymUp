<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Achievement extends Model
{
    protected $fillable = [
        'code',
        'title',
        'description',
        'metric',
        'target_value',
        'points_reward',
        'icon',
    ];
}
