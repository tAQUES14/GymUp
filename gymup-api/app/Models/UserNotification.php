<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserNotification extends Model
{
    protected $table = 'user_notifications';

    protected $fillable = [
        'user_id',
        'title',
        'message',
        'read_at',
    ];

    protected $casts = [
        'read_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function isRead(): bool
    {
        return $this->read_at !== null;
    }

    /**
     * Helper: create a notification for a user in one call.
     * Designed to be called inside an existing DB transaction.
     */
    public static function notify(int $userId, string $title, string $message): void
    {
        static::create([
            'user_id' => $userId,
            'title'   => $title,
            'message' => $message,
        ]);
    }
}
