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

    /**
     * Get limit for a given event + volunteer type from event.volunteer_needs JSON.
     */
    protected function getRoleLimit(Event $event, string $type): int
    {
        $needs = $event->volunteer_needs ?? [];

        if (!is_array($needs)) {
            return 0;
        }

        if (!isset($needs[$type]) || !is_array($needs[$type])) {
            return 0;
        }

        return (int) ($needs[$type]['limit'] ?? 0);
    }

    /**
     * Count accepted volunteers for (event, type).
     */
    protected function acceptedCount(int $eventId, string $type): int
    {
        return VolunteerRequest::where('event_id', $eventId)
            ->where('volunteer_type', $type)
            ->where('status', 'accepted')
            ->count();
    }

    // ======================
    // User side
    // ======================

    /**
     * user يقدّم طلب تطوّع على event معيّن
     * POST /api/events/{event}/volunteer-requests
     * Body: { "volunteer_type": "event_organizer" }
     */
    public function store(Request $request, $eventId)
    {
        $user  = $this->requireNormalUser($request);
        $event = Event::findOrFail($eventId);

        $data = $request->validate([
            'volunteer_type' => ['required', 'string', 'max:255'],
        ]);

        $type  = $data['volunteer_type'];

        // ✅ لازم الدور يكون موجود ضمن volunteer_needs تبع الحدث
        $limit = $this->getRoleLimit($event, $type);

        if ($limit <= 0) {
            return response()->json([
                'message' => 'This volunteer role is not available for this event.',
            ], 422);
        }

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

        // ✅ تأكد في spots left (نحسب accepted فقط)
        $accepted = $this->acceptedCount($event->id, $type);

        if ($accepted >= $limit) {
            return response()->json([
                'message' => 'No spots left for this volunteer role.',
            ], 422);
        }

        $vr = VolunteerRequest::create([
            'event_id'       => $event->id,
            'user_id'        => $user->id,
            'volunteer_type' => $type,
            'status'         => 'pending',
        ]);

        return response()->json([
            'message' => 'Volunteer request submitted successfully',
            'request' => $vr->load('event:id,name', 'user:id,name,email'),
        ], 201);
    }

    /**
     * طلبات التطوّع الخاصة باليوزر
     * GET /api/volunteer-requests/me
     */
    public function myRequests(Request $request)
    {
        $user = $request->user();

        $requests = VolunteerRequest::where('user_id', $user->id)
            ->with('event:id,name,start_time,end_time,location,venue')
            ->orderByDesc('created_at')
            ->get();

        return response()->json($requests);
    }

    // ======================
    // Organizer side
    // ======================

    /**
     * كل طلبات التطوّع على أحداث هذا المنظّم
     * GET /api/organizer/volunteer-requests
     */
    public function organizerIndex(Request $request)
    {
        $organizer = $this->requireOrganizer($request);

        $requests = VolunteerRequest::whereHas('event', function ($q) use ($organizer) {
                $q->where('organizer_id', $organizer->id);
            })
            ->with('user:id,name,email', 'event:id,name,start_time,end_time,location,venue,organizer_id')
            ->orderBy('status')
            ->orderByDesc('created_at')
            ->get();

        return response()->json($requests);
    }

    /**
     * قبول طلب تطوّع
     * POST /api/organizer/volunteer-requests/{id}/approve
     * Body: { "reward": "..." }
     */
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

        // ✅ قبل القبول، تأكد ما رح نتجاوز limit
        $limit = $this->getRoleLimit($vr->event, $vr->volunteer_type);

        if ($limit > 0) {
            $accepted = $this->acceptedCount($vr->event_id, $vr->volunteer_type);

            if ($accepted >= $limit) {
                return response()->json([
                    'message' => 'No spots left for this volunteer role.',
                ], 422);
            }
        } else {
            // لو المنظم حذف role من volunteer_needs بعد ما صار في طلبات pending
            return response()->json([
                'message' => 'This volunteer role is no longer available for this event.',
            ], 422);
        }

        $vr->reward = $data['reward'];
        $vr->status = 'accepted';
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

    /**
     * رفض طلب تطوّع
     * POST /api/organizer/volunteer-requests/{id}/reject
     * Body: { "reason": "..." }
     */
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
