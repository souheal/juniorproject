<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\OrganizerRequest;
use App\Models\OrganizerProfile;
use App\Models\Role;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Http\Request;

class OrganizerRequestAdminController extends Controller
{
    /**
     * عرض كل طلبات المنظّمين
     */
    public function index()
{
    $requests = OrganizerRequest::with('user:id,name,email')
        ->orderByRaw("
            CASE status
                WHEN 'pending' THEN 1
                WHEN 'approved' THEN 2
                WHEN 'rejected' THEN 3
                ELSE 4
            END
        ")
        ->orderByDesc('created_at')
        ->get();

    return response()->json($requests);
}


    /**
     * قبول الطلب:
     * - تغيير status إلى approved
     * - إعطاء اليوزر role = organizer
     * - إنشاء OrganizerProfile (لو مش موجود)
     * - إرسال إشعار لليوزر أنه أصبح منظّم
     */
    public function approve(Request $request, $id)
    {
        $orgRequest = OrganizerRequest::with('user')->findOrFail($id);

        if ($orgRequest->status === 'approved') {
            return response()->json([
                'message' => 'Request is already approved',
            ], 422);
        }

        // 1) عدّل حالة الطلب
        $orgRequest->status = 'approved';
        $orgRequest->admin_comment = $request->input('admin_comment');
        $orgRequest->save();

        // 2) حوّل اليوزر إلى organizer
        $user = $orgRequest->user;

        if ($user) {
            $organizerRoleId = Role::where('name', 'organizer')->value('id');

            if ($organizerRoleId) {
                $user->role_id = $organizerRoleId;
                $user->save();
            }

            // 3) أنشئ OrganizerProfile لو مش موجود
            OrganizerProfile::firstOrCreate(
                ['user_id' => $user->id],
                [
                    'website'  => null,  // ممكن تعدّلها لاحقاً من الـ app
                    'verified' => true,
                ]
            );

            // 4) إشعار لليوزر أنه تم قبوله كمنظّم
            Notification::create([
                'user_id'     => $user->id,
                'event_id'    => null,
                'type'        => 'organizer_request_approved',
                'content'     => 'Your organizer request for "' . $orgRequest->organization_name . '" has been approved.',
                'read_status' => false,
            ]);
        }

        return response()->json([
            'message' => 'Organizer request approved and user upgraded to organizer',
            'request' => $orgRequest->load('user:id,name,email'),
        ]);
    }

    /**
     * رفض الطلب:
     * - status = rejected
     * - إرسال إشعار لليوزر أنه تم الرفض
     */
    public function reject(Request $request, $id)
    {
        $data = $request->validate([
            'admin_comment' => ['nullable', 'string', 'max:1000'],
        ]);

        $orgRequest = OrganizerRequest::with('user')->findOrFail($id);

        $orgRequest->status = 'rejected';
        $orgRequest->admin_comment = $data['admin_comment'] ?? null;
        $orgRequest->save();

        if ($orgRequest->user) {
            $reason = $orgRequest->admin_comment
                ? ' Reason: ' . $orgRequest->admin_comment
                : '';

            Notification::create([
                'user_id'     => $orgRequest->user->id,
                'event_id'    => null,
                'type'        => 'organizer_request_rejected',
                'content'     => 'Your organizer request for "' . $orgRequest->organization_name . '" has been rejected.' . $reason,
                'read_status' => false,
            ]);
        }

        return response()->json([
            'message' => 'Organizer request rejected',
            'request' => $orgRequest->load('user:id,name,email'),
        ]);
    }
}
