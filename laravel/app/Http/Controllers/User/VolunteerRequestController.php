<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\VolunteerRequest;
use App\Models\Notification;
use Illuminate\Http\Request;

class VolunteerRequestController extends Controller
{
    // ===== Helpers =====

    protected function requireNormalUser(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->role || $user->role->name !== 'user') {
            abort(response()->json([
                'message' => 'Only normal users can submit volunteer requests',
            ], 403));
        }

        return $user;
    }

    protected function requireOrganizer(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->role || $user->role->name !== 'organizer') {
            abort(response()->json([
                'message' => 'Only organizers can manage volunteer requests',
            ], 403));
        }

        return $user;
    }

    // ======================
    // User side
    // ======================

    // user يقدّم طلب تطوّع على event معيّن
    public function store(Request $request, $eventId)
    {
        $user  = $this->requireNormalUser($request);
        $event = Event::findOrFail($eventId);

        $data = $request->validate([
            'volunteer_type' => ['required', 'string', 'max:255'],
        ]);

        // منع تكرار طلب لنفس الحدث (pending أو accepted)
        $exists = VolunteerRequest::where('event_id', $event->id)
            ->where('user_id', $user->id)
            ->whereIn('status', ['pending', 'accepted'])
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'You already have a volunteer request for this event',
            ], 422);
        }

        $vr = VolunteerRequest::create([
            'event_id'       => $event->id,
            'user_id'        => $user->id,
            'volunteer_type' => $data['volunteer_type'],
            'status'         => 'pending',
        ]);

        return response()->json([
            'message' => 'Volunteer request submitted successfully',
            'request' => $vr->load('event:id,name', 'user:id,name,email'),
        ], 201);
    }

    // طلبات التطوّع الخاصة باليوزر
    public function myRequests(Request $request)
    {
        $user = $request->user();

        $requests = VolunteerRequest::where('user_id', $user->id)
            ->with('event:id,name,start_time,location')
            ->orderByDesc('created_at')
            ->get();

        return response()->json($requests);
    }

    // ======================
    // Organizer side
    // ======================

    // كل طلبات التطوّع على أحداث هذا المنظّم
    public function organizerIndex(Request $request)
    {
        $organizer = $this->requireOrganizer($request);

        $requests = VolunteerRequest::whereHas('event', function ($q) use ($organizer) {
                $q->where('organizer_id', $organizer->id);
            })
            ->with('user:id,name,email', 'event:id,name,start_time,location')
            ->orderBy('status')
            ->orderByDesc('created_at')
            ->get();

        return response()->json($requests);
    }

    public function approve(Request $request, $id)
    {
        $organizer = $this->requireOrganizer($request);

        $data = $request->validate([
            'reward' => ['required', 'string', 'max:255'],
        ]);

        $vr = VolunteerRequest::with('event', 'user')->findOrFail($id);

        // تأكد أن الإيفنت تابع للمنظّم الحالي
        if (! $vr->event || $vr->event->organizer_id !== $organizer->id) {
            return response()->json([
                'message' => 'You can only manage volunteer requests for your own events',
            ], 403);
        }

        // بس pending بينقبل
        if ($vr->status !== 'pending') {
            return response()->json([
                'message' => 'Only pending requests can be accepted',
            ], 422);
        }

        $vr->reward = $data['reward'];
        $vr->status = 'accepted';   // مطابق للـ enum في migration
        $vr->save();

        // إشعار لليوزر إنه اتقبل
        Notification::create([
            'user_id'     => $vr->user_id,
            'event_id'    => $vr->event_id,
            'type'        => 'volunteer_request_accepted',
            'content'     => 'Your volunteer request for "' . $vr->event->name . '" has been accepted. Reward: ' . $vr->reward,
            'read_status' => false,
        ]);

        return response()->json([
            'message' => 'Volunteer request accepted successfully',
            'request' => $vr->load('event:id,name', 'user:id,name,email'),
        ]);
    }

    public function reject(Request $request, $id)
    {
        $organizer = $this->requireOrganizer($request);

        $data = $request->validate([
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $vr = VolunteerRequest::with('event', 'user')->findOrFail($id);

        if (! $vr->event || $vr->event->organizer_id !== $organizer->id) {
            return response()->json([
                'message' => 'You can only manage volunteer requests for your own events',
            ], 403);
        }

        if ($vr->status !== 'pending') {
            return response()->json([
                'message' => 'Only pending requests can be rejected',
            ], 422);
        }

        $vr->status = 'rejected';
        $vr->save();

        $reasonText = $data['reason'] ? (' Reason: ' . $data['reason']) : '';

        Notification::create([
            'user_id'     => $vr->user_id,
            'event_id'    => $vr->event_id,
            'type'        => 'volunteer_request_rejected',
            'content'     => 'Your volunteer request for "' . $vr->event->name . '" has been rejected.' . $reasonText,
            'read_status' => false,
        ]);

        return response()->json([
            'message' => 'Volunteer request rejected',
            'request' => $vr->load('event:id,name', 'user:id,name,email'),
        ]);
    }
}
