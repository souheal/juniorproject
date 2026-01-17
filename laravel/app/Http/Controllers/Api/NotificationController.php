<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    // كل إشعارات المستخدم
    public function index(Request $request)
    {
        $user = $request->user();

        $notifications = Notification::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($notifications);
    }

    // عدد الإشعارات غير المقروءة (للبادج الحمراء فوق الأيقونة)
    public function unreadCount(Request $request)
    {
        $count = Notification::where('user_id', $request->user()->id)
            ->where('read_status', false)
            ->count();

        return response()->json(['unread_count' => $count]);
    }

    // تعليم إشعار كمقروء
    public function markAsRead($id, Request $request)
    {
        $notification = Notification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $notification->read_status = true;
        $notification->save();

        return response()->json(['message' => 'Notification marked as read']);
    }
}
