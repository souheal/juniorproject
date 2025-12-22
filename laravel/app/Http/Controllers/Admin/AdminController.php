<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Event;
use App\Models\OrganizerRequest;
use App\Models\Ticket;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    /**
     * Get dashboard statistics
     */
    public function dashboard()
    {
        // Get counts
        $totalUsers = User::count();
        $totalEvents = Event::count();
        $totalOrganizers = User::whereHas('role', fn($q) => $q->where('name', 'organizer'))->count();
        $pendingRequests = OrganizerRequest::where('status', 'pending')->count();

        // Calculate revenue from tickets
        $totalRevenue = Ticket::where('status', 'confirmed')
            ->join('events', 'tickets.event_id', '=', 'events.id')
            ->sum('events.ticket_price');

        // Recent organizer requests
        $recentRequests = OrganizerRequest::with('user:id,name,email')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(fn($r) => [
                'id' => $r->id,
                'name' => $r->user->name ?? 'Unknown',
                'organization' => $r->organization_name,
                'status' => $r->status,
                'date' => $r->created_at->diffForHumans(),
            ]);

        // Recent events
        $recentEvents = Event::with('user:id,name')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(fn($e) => [
                'id' => $e->id,
                'name' => $e->title,
                'organizer' => $e->user->name ?? 'Unknown',
                'date' => $e->start_date,
                'status' => $e->status ?? 'published',
            ]);

        // Monthly stats for chart (last 6 months)
        $monthlyStats = [];
        for ($i = 5; $i >= 0; $i--) {
            $date = now()->subMonths($i);
            $monthlyStats[] = [
                'month' => $date->format('M'),
                'users' => User::whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)
                    ->count(),
                'events' => Event::whereYear('created_at', $date->year)
                    ->whereMonth('created_at', $date->month)
                    ->count(),
            ];
        }

        return response()->json([
            'stats' => [
                'total_users' => $totalUsers,
                'total_events' => $totalEvents,
                'total_organizers' => $totalOrganizers,
                'pending_requests' => $pendingRequests,
                'total_revenue' => $totalRevenue ?? 0,
            ],
            'recent_requests' => $recentRequests,
            'recent_events' => $recentEvents,
            'monthly_stats' => $monthlyStats,
        ]);
    }

    /**
     * Get all users
     */
    public function users(Request $request)
    {
        $query = User::with('role:id,name');

        // Search filter
        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ilike', "%{$search}%")
                  ->orWhere('email', 'ilike', "%{$search}%")
                  ->orWhere('phone', 'ilike', "%{$search}%")
                  ->orWhere('location', 'ilike', "%{$search}%");
            });
        }

        // Role filter
        if ($request->has('role') && $request->role !== 'all') {
            $query->whereHas('role', fn($q) => $q->where('name', $request->role));
        }

        $users = $query->orderByDesc('created_at')->get();

        // Stats
        $stats = [
            'total' => User::count(),
            'users' => User::whereHas('role', fn($q) => $q->where('name', 'user'))->count(),
            'organizers' => User::whereHas('role', fn($q) => $q->where('name', 'organizer'))->count(),
            'admins' => User::whereHas('role', fn($q) => $q->where('name', 'admin'))->count(),
        ];

        return response()->json([
            'users' => $users,
            'stats' => $stats,
        ]);
    }

    /**
     * Get single user
     */
    public function showUser($id)
    {
        $user = User::with(['role:id,name', 'tickets.event', 'organizerProfile'])
            ->findOrFail($id);

        return response()->json(['user' => $user]);
    }

    /**
     * Get all events
     */
    public function events(Request $request)
    {
        $query = Event::with('user:id,name');

        // Search filter
        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'ilike', "%{$search}%")
                  ->orWhere('location', 'ilike', "%{$search}%");
            });
        }

        // Status filter
        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $events = $query->orderByDesc('created_at')->get()->map(fn($e) => [
            'id' => $e->id,
            'name' => $e->title,
            'organizer' => $e->user->name ?? 'Unknown',
            'organizer_id' => $e->user_id,
            'date' => $e->start_date,
            'end_date' => $e->end_date,
            'location' => $e->location,
            'status' => $e->status ?? 'published',
            'ticket_price' => $e->ticket_price,
            'max_attendees' => $e->max_attendees,
            'tickets_sold' => $e->tickets()->where('status', 'confirmed')->count(),
            'image' => $e->image,
            'created_at' => $e->created_at,
        ]);

        // Stats
        $stats = [
            'total' => Event::count(),
            'published' => Event::where('status', 'published')->count(),
            'draft' => Event::where('status', 'draft')->count(),
            'cancelled' => Event::where('status', 'cancelled')->count(),
        ];

        return response()->json([
            'events' => $events,
            'stats' => $stats,
        ]);
    }

    /**
     * Delete an event
     */
    public function deleteEvent($id)
    {
        $event = Event::findOrFail($id);
        $event->delete();

        return response()->json([
            'message' => 'Event deleted successfully',
        ]);
    }

    /**
     * Get organizer requests with user events
     */
    public function organizerRequests(Request $request)
    {
        $query = OrganizerRequest::with(['user:id,name,email,phone', 'user.organizerProfile']);

        // Status filter
        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        // Search filter
        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('organization_name', 'ilike', "%{$search}%")
                  ->orWhereHas('user', fn($uq) =>
                      $uq->where('name', 'ilike', "%{$search}%")
                         ->orWhere('email', 'ilike', "%{$search}%")
                  );
            });
        }

        $requests = $query->orderByRaw("
            CASE status
                WHEN 'pending' THEN 1
                WHEN 'approved' THEN 2
                WHEN 'rejected' THEN 3
                ELSE 4
            END
        ")->orderByDesc('created_at')->get();

        // For approved organizers, get their events
        $requests = $requests->map(function ($r) {
            $data = [
                'id' => $r->id,
                'name' => $r->user->name ?? 'Unknown',
                'email' => $r->user->email ?? '',
                'phone' => $r->user->phone ?? '',
                'organization' => $r->organization_name,
                'bio' => $r->description ?? '',
                'status' => $r->status,
                'date' => $r->created_at->toDateString(),
                'created_at' => $r->created_at,
                'documents' => 0, // Placeholder
                'events' => [],
            ];

            // Get events for approved organizers
            if ($r->status === 'approved' && $r->user) {
                $events = Event::where('user_id', $r->user->id)
                    ->get()
                    ->map(fn($e) => [
                        'id' => $e->id,
                        'title' => $e->title,
                        'date' => $e->start_date,
                        'location' => $e->location,
                        'attendees' => $e->max_attendees ?? 0,
                        'tickets_sold' => $e->tickets()->where('status', 'confirmed')->count(),
                        'status' => $e->status ?? 'published',
                    ]);
                $data['events'] = $events;
            }

            return $data;
        });

        // Stats
        $stats = [
            'total' => OrganizerRequest::count(),
            'pending' => OrganizerRequest::where('status', 'pending')->count(),
            'approved' => OrganizerRequest::where('status', 'approved')->count(),
            'rejected' => OrganizerRequest::where('status', 'rejected')->count(),
        ];

        return response()->json([
            'requests' => $requests,
            'stats' => $stats,
        ]);
    }
}
