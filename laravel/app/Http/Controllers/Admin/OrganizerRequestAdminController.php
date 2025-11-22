<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\OrganizerRequest;
use App\Models\Role;
use Illuminate\Http\Request;
use App\Models\Notification;


class OrganizerRequestAdminController extends Controller
{
    // 🧾 كل الطلبات (ممكن بعدين تعمل فلترة حسب status)
    public function index()
    {
        $requests = OrganizerRequest::with('user:id,name,email')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($requests);
    }

    // ✅ قبول الطلب
    public function approve($id, Request $request)
{
    $organizerRequest = OrganizerRequest::findOrFail($id);

    $organizerRequest->status = 'approved';
    $organizerRequest->admin_comment = $request->input('admin_comment');
    $organizerRequest->save();

    // إنشاء إشعار للمستخدم
    Notification::create([
        'user_id'     => $organizerRequest->user_id,
        'event_id'    => null, // ما في event هون
        'type'        => 'organizer_request_approved',
        'content'     => 'Your organizer request for "'.$organizerRequest->organization_name.'" has been approved.',
        'read_status' => false,
    ]);

    return response()->json([
        'message' => 'Organizer request approved successfully',
    ]);
}

    // ❌ رفض الطلب
    public function reject($id, Request $request)
{
    $organizerRequest = OrganizerRequest::findOrFail($id);

    $organizerRequest->status = 'rejected';
    $organizerRequest->admin_comment = $request->input('admin_comment');
    $organizerRequest->save();

    Notification::create([
        'user_id'     => $organizerRequest->user_id,
        'event_id'    => null,
        'type'        => 'organizer_request_rejected',
        'content'     => 'Your organizer request for "'.$organizerRequest->organization_name.'" has been rejected.',
        'read_status' => false,
    ]);

    return response()->json([
        'message' => 'Organizer request rejected successfully',
    ]);
}

}
