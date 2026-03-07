<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Reward extends Model
{
    use HasFactory;

    protected $fillable = [
        'gym_id',
        'name',
        'description',
        'points_cost',
        'stock',
        'discount_percent',
        'active',
    ];

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }

    public function redemptions()
    {
        return $this->hasMany(Redemption::class);
    }
}