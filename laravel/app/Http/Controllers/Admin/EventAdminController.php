<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\VolunteerRequest;
use Illuminate\Http\Request;

class EventAdminController extends Controller
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

    /**
     * GET /api/admin/events
     * - stats
     * - list with filters
     */
    public function index(Request $request)
    {
        $this->requireAdmin($request);

        $query = Event::query()->with(['organizer:id,name']);

        // status filter
        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        // search
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ILIKE', "%{$search}%")
                  ->orWhere('location', 'ILIKE', "%{$search}%")
                  ->orWhere('city', 'ILIKE', "%{$search}%")
                  ->orWhere('venue', 'ILIKE', "%{$search}%");
            });
        }

        $perPage = $request->integer('per_page', 10);

        $events = $query
            ->orderByDesc('created_at')
            ->paginate($perPage);

        // stats
        $total     = Event::count();
        $published = Event::where('status', 'published')->count();
        $draft     = Event::where('status', 'draft')->count();
        $cancelled = Event::where('status', 'cancelled')->count(); // إذا ما عندك cancelled رح تكون 0

        return response()->json([
            'stats' => [
                'total_events' => $total,
                'published'    => $published,
                'draft'        => $draft,
                'cancelled'    => $cancelled,
            ],
            'events' => $events,
        ]);
    }

    /**
     * DELETE /api/admin/events/{id}
     */
    public function destroy(Request $request, $id)
    {
        $this->requireAdmin($request);

        $event = Event::findOrFail($id);

        $hasTickets    = Ticket::where('event_id', $event->id)->exists();
        $hasVolunteers = VolunteerRequest::where('event_id', $event->id)->exists();

        if ($hasTickets || $hasVolunteers) {
            return response()->json([
                'message' => 'Cannot delete event that has tickets or volunteers.',
            ], 422);
        }

        // إذا عندك picture وتريد تحذفها من storage، اعملها هون (حسب كودك في ManageEventController)

        $event->delete();

        return response()->json([
            'message' => 'Event deleted successfully.',
        ]);
    }
}
