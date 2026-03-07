<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BodyWeightLog extends Model
{
    protected $fillable = ['user_id', 'weight', 'recorded_at'];

    protected $casts = [
        'recorded_at' => 'date',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
