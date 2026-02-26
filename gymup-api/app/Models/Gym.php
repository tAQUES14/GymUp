<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Gym extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'address',
        'active'
    ];

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function rewards()
    {
        return $this->hasMany(Reward::class);
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
}