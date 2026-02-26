<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Checkin extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'gym_id',
        'checkin_date',
        'checked_in_at'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }
}