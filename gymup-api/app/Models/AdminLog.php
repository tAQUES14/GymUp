<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdminLog extends Model
{
    protected $fillable = [
        'admin_id',
        'gym_id',
        'action',
        'target_type',
        'target_id',
        'description',
    ];

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }

    /**
     * Helper to create a log entry inside an existing transaction.
     */
    public static function record(User $admin, string $action, string $targetType, int $targetId, string $description): void
    {
        static::create([
            'admin_id'    => $admin->id,
            'gym_id'      => $admin->gym_id,
            'action'      => $action,
            'target_type' => $targetType,
            'target_id'   => $targetId,
            'description' => $description,
        ]);
    }
}
