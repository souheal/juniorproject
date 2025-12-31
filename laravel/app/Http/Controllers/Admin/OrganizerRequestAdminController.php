<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\OrganizerRequest;
use App\Models\OrganizerProfile;
use App\Models\Role;
use App\Models\Notification;
use Illuminate\Http\Request;

class OrganizerRequestAdminController extends Controller
{
    protected function requireAdmin(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->role || $user->role->name !== 'admin') {
            abort(response()->json([
                'message' => 'Only admins can perform this action.',
            ], 403));
        }

        return $user;
    }

    public function index(Request $request)
    {
        $this->requireAdmin($request);

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

        // stats للصورة (156/23/112/21)
        $total    = OrganizerRequest::count();
        $pending  = OrganizerRequest::where('status', 'pending')->count();
        $approved = OrganizerRequest::where('status', 'approved')->count();
        $rejected = OrganizerRequest::where('status', 'rejected')->count();

        return response()->json([
            'stats' => [
                'total'    => $total,
                'pending'  => $pending,
                'approved' => $approved,
                'rejected' => $rejected,
            ],
            'requests' => $requests,
        ]);
    }

    public function approve(Request $request, $id)
    {
        $this->requireAdmin($request);

        $orgRequest = OrganizerRequest::with('user')->findOrFail($id);

        if ($orgRequest->status === 'approved') {
            return response()->json([
                'message' => 'Request is already approved',
            ], 422);
        }

        $orgRequest->status = 'approved';
        $orgRequest->admin_comment = $request->input('admin_comment');
        $orgRequest->save();

        $user = $orgRequest->user;

        if ($user) {
            $organizerRoleId = Role::where('name', 'organizer')->value('id');

            if ($organizerRoleId) {
                $user->role_id = $organizerRoleId;
                $user->save();
            }

OrganizerProfile::updateOrCreate(
    ['user_id' => $user->id],
    [
        'organization_name' => $orgRequest->organization_name,
        'description'       => $orgRequest->description,
        'contact_email'     => $user->email,
        'contact_phone'     => $user->phone, // optional
        'website'           => null,
        'facebook'          => null,
        'instagram'         => null,
        'twitter'           => null,
        'verified'          => true,
    ]
);


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

    public function reject(Request $request, $id)
    {
        $this->requireAdmin($request);

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
