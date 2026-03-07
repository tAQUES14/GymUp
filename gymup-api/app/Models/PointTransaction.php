<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PointTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'gym_id',
        'type',
        'category',
        'points',
        'description',
        'reference_id',
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