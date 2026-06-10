<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class Gym extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'address',
        'city',
        'active',
        'chain_id',
        'invite_code',
        'qr_token',
        'qr_generated_at',
    ];

    protected $casts = [
        'active' => 'boolean',
        'qr_generated_at' => 'datetime',
    ];

    protected static function boot(): void
    {
        parent::boot();

        static::creating(function (self $gym) {
            if (empty($gym->invite_code)) {
                $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
                do {
                    $code = '';
                    for ($i = 0; $i < 6; $i++) {
                        $code .= $chars[random_int(0, strlen($chars) - 1)];
                    }
                } while (self::where('invite_code', $code)->exists());
                $gym->invite_code = $code;
            }
            if (empty($gym->qr_token)) {
                $gym->qr_token        = (string) Str::uuid();
                $gym->qr_generated_at = now();
            }
        });
    }

    public function chain()
    {
        return $this->belongsTo(GymChain::class, 'chain_id');
    }

    public function trainers()
    {
        return $this->belongsToMany(User::class, 'trainer_gyms', 'gym_id', 'trainer_id')
            ->withPivot('is_primary');
    }

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
