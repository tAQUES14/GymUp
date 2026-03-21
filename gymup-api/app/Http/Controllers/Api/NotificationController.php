<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserNotification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * GET /api/user/notifications
     *
     * Returns the authenticated user's notifications, newest first.
     * Includes unread_count for badge display in the app.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $notifications = UserNotification::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->paginate(20);

        $unreadCount = UserNotification::where('user_id', $user->id)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'data'         => $notifications->items(),
            'unread_count' => $unreadCount,
            'meta'         => [
                'current_page' => $notifications->currentPage(),
                'last_page'    => $notifications->lastPage(),
                'total'        => $notifications->total(),
            ],
        ]);
    }

    /**
     * POST /api/user/notifications/{id}/read
     *
     * Marks a single notification as read.
     */
    public function markRead(Request $request, int $id)
    {
        $notification = UserNotification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$notification) {
            return response()->json(['message' => 'Notificação não encontrada.'], 404);
        }

        if (!$notification->read_at) {
            $notification->update(['read_at' => now()]);
        }

        return response()->json(['message' => 'Notificação marcada como lida.']);
    }

    /**
     * POST /api/user/notifications/read-all
     *
     * Marks all unread notifications as read in one query.
     */
    public function markAllRead(Request $request)
    {
        UserNotification::where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'Todas as notificações foram marcadas como lidas.']);
    }
}
