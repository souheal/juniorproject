<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\VolunteerRequest;
use App\Models\Notification;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

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

        if (!is_array($needs)) return 0;
        if (!isset($needs[$type]) || !is_array($needs[$type])) return 0;

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
     * user submits a volunteer request for an event
     * POST /api/events/{event}/volunteer-requests
     */
    public function store(Request $request, $eventId)
    {
        $user  = $this->requireNormalUser($request);
        $event = Event::findOrFail($eventId);

        $data = $request->validate([
            'volunteer_type'        => ['required', 'string', 'max:255'],

            // NEW applicant details
            'availability'          => ['nullable', 'string', 'max:2000'],
            'previous_experience'   => ['nullable', 'string', 'max:5000'],
            'skills'                => ['nullable', 'string', 'max:2000'],
            'added_value'           => ['nullable', 'string', 'max:3000'],

            // multiple links (array of URLs)
            'social_links'          => ['nullable', 'array', 'max:10'],
            'social_links.*'        => ['string', 'url', 'max:500'],
        ]);

        $type  = $data['volunteer_type'];

        // role must exist in event.volunteer_needs
        $limit = $this->getRoleLimit($event, $type);
        if ($limit <= 0) {
            return response()->json([
                'message' => 'This volunteer role is not available for this event.',
            ], 422);
        }

        // prevent duplicate request for same event (pending or accepted)
        $exists = VolunteerRequest::where('event_id', $event->id)
            ->where('user_id', $user->id)
            ->whereIn('status', ['pending', 'accepted'])
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'You already have a volunteer request for this event',
            ], 422);
        }

        // check spots left (accepted only)
        $accepted = $this->acceptedCount($event->id, $type);
        if ($accepted >= $limit) {
            return response()->json([
                'message' => 'No spots left for this volunteer role.',
            ], 422);
        }

        $vr = VolunteerRequest::create([
            'event_id'             => $event->id,
            'user_id'              => $user->id,
            'volunteer_type'       => $type,
            'availability'         => $data['availability'] ?? null,
            'previous_experience'  => $data['previous_experience'] ?? null,
            'social_links'         => $data['social_links'] ?? null,
            'skills'               => $data['skills'] ?? null,
            'added_value'          => $data['added_value'] ?? null,
            'status'               => 'pending',
        ]);

        return response()->json([
            'message' => 'Volunteer request submitted successfully',
            'request' => $vr->load('event:id,name', 'user:id,name,email'),
        ], 201);
    }

    /**
     * user gets their own volunteer requests
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
     * organizer gets all volunteer requests for their events
     * GET /api/organizer/volunteer-requests
     *
     * Organizer will see:
     * - user name/email/phone
     * - availability, previous_experience, social_links, skills, added_value
     */
    public function organizerIndex(Request $request)
    {
        $organizer = $this->requireOrganizer($request);

        $requests = VolunteerRequest::whereHas('event', function ($q) use ($organizer) {
                $q->where('organizer_id', $organizer->id);
            })
            ->with(
                'user:id,name,email,phone',
                'event:id,name,start_time,end_time,location,venue,organizer_id'
            )
            ->orderBy('status')
            ->orderByDesc('created_at')
            ->get();

        return response()->json($requests);
    }

    /**
     * accept volunteer request
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

        // ensure event belongs to organizer
        if (! $vr->event || $vr->event->organizer_id !== $organizer->id) {
            return response()->json([
                'message' => 'You can only manage volunteer requests for your own events',
            ], 403);
        }

        // only pending can be accepted
        if ($vr->status !== 'pending') {
            return response()->json([
                'message' => 'Only pending requests can be accepted',
            ], 422);
        }

        // check limit before accepting
        $limit = $this->getRoleLimit($vr->event, $vr->volunteer_type);

        if ($limit > 0) {
            $accepted = $this->acceptedCount($vr->event_id, $vr->volunteer_type);
            if ($accepted >= $limit) {
                return response()->json([
                    'message' => 'No spots left for this volunteer role.',
                ], 422);
            }
        } else {
            return response()->json([
                'message' => 'This volunteer role is no longer available for this event.',
            ], 422);
        }

        $vr->reward = $data['reward'];
        $vr->status = 'accepted';

        // If you have these columns (recommended for exports/audit)
        if (property_exists($vr, 'reviewed_at')) $vr->reviewed_at = now();
        if (property_exists($vr, 'reviewed_by')) $vr->reviewed_by = $organizer->id;
        if (property_exists($vr, 'rejection_reason')) $vr->rejection_reason = null;

        $vr->save();

        Notification::create([
            'user_id'     => $vr->user_id,
            'event_id'    => $vr->event_id,
            'type'        => 'volunteer_request_accepted',
            'content'     => 'Your volunteer request for "' . $vr->event->name . '" has been accepted. Reward: ' . $vr->reward,
            'read_status' => false,
        ]);

        return response()->json([
            'message' => 'Volunteer request accepted successfully',
            'request' => $vr->load('event:id,name', 'user:id,name,email,phone'),
        ]);
    }

    /**
     * reject volunteer request
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

        if (property_exists($vr, 'reviewed_at')) $vr->reviewed_at = now();
        if (property_exists($vr, 'reviewed_by')) $vr->reviewed_by = $organizer->id;
        if (property_exists($vr, 'rejection_reason')) $vr->rejection_reason = $data['reason'] ?? null;

        $vr->save();

        $reasonText = ($data['reason'] ?? null) ? (' Reason: ' . $data['reason']) : '';

        Notification::create([
            'user_id'     => $vr->user_id,
            'event_id'    => $vr->event_id,
            'type'        => 'volunteer_request_rejected',
            'content'     => 'Your volunteer request for "' . $vr->event->name . '" has been rejected.' . $reasonText,
            'read_status' => false,
        ]);

        return response()->json([
            'message' => 'Volunteer request rejected',
            'request' => $vr->load('event:id,name', 'user:id,name,email,phone'),
        ]);
    }

    /**
     * CSV export for organizer's volunteer requests
     * GET /api/organizer/volunteer-requests/export
     */
    public function export(Request $request)
    {
        $organizer = $this->requireOrganizer($request);

        $data = $request->validate([
            'event_id' => ['nullable', 'integer'],
            'status'   => ['nullable', 'in:pending,accepted,rejected'],
            'from'     => ['nullable', 'date'],
            'to'       => ['nullable', 'date'],
        ]);

        $query = VolunteerRequest::query()
            ->whereHas('event', function ($q) use ($organizer) {
                $q->where('organizer_id', $organizer->id);
            })
            ->with([
                'user:id,name,email,phone',
                'event:id,name,start_time,end_time,location,venue,organizer_id',
            ])
            ->orderByDesc('created_at');

        if (!empty($data['event_id'])) $query->where('event_id', $data['event_id']);
        if (!empty($data['status']))   $query->where('status', $data['status']);
        if (!empty($data['from']))     $query->whereDate('created_at', '>=', $data['from']);
        if (!empty($data['to']))       $query->whereDate('created_at', '<=', $data['to']);

        $filename = 'volunteer_requests_' . now()->format('Y-m-d_H-i-s') . '.csv';

        return new StreamedResponse(function () use ($query) {
            $handle = fopen('php://output', 'w');

            // UTF-8 BOM for Excel + Arabic
            fprintf($handle, chr(0xEF).chr(0xBB).chr(0xBF));

            fputcsv($handle, [
                'Request ID',
                'Event Name',
                'User Name',
                'User Email',
                'User Phone',
                'Volunteer Type',
                'Availability',
                'Previous Experience',
                'Social Links',
                'Skills',
                'Added Value',
                'Status',
                'Reward',
                'Created At',
            ]);

            $query->chunk(500, function ($requests) use ($handle) {
                foreach ($requests as $vr) {
                    $links = is_array($vr->social_links) ? implode(' | ', $vr->social_links) : null;

                    fputcsv($handle, [
                        $vr->id,
                        optional($vr->event)->name,
                        optional($vr->user)->name,
                        optional($vr->user)->email,
                        optional($vr->user)->phone,
                        $vr->volunteer_type,
                        $vr->availability,
                        $vr->previous_experience,
                        $links,
                        $vr->skills,
                        $vr->added_value,
                        $vr->status,
                        $vr->reward,
                        $vr->created_at?->toDateTimeString(),
                    ]);
                }
            });

            fclose($handle);
        }, 200, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="'.$filename.'"',
        ]);
    }
}
