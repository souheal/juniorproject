<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\VolunteerRequest;
use Illuminate\Http\Request;

class OrganizerEventStatsController extends Controller
{
    /**
     * Dashboard لارقام حدث معيّن (خاص بالمنظم صاحب الحدث).
     * GET /api/organizer/events/{event}/dashboard
     */
    public function dashboard(Request $request, Event $event)
    {
        $user = $request->user();

        // تأكد إنه المنظم صاحب الحدث
        if (!$user || !$user->role || $user->role->name !== 'organizer' || $event->organizer_id !== $user->id) {
            return response()->json([
                'message' => 'You are not allowed to view this event dashboard.',
            ], 403);
        }

        // إحصائيات التذاكر
        $totalTickets     = Ticket::where('event_id', $event->id)->count();
        $paidTickets      = Ticket::where('event_id', $event->id)->where('payment_status', 'paid')->count();
        $pendingTickets   = Ticket::where('event_id', $event->id)->where('payment_status', 'pending')->count();
        $cancelledTickets = Ticket::where('event_id', $event->id)->where('payment_status', 'cancelled')->count();

        $scannedTickets   = Ticket::where('event_id', $event->id)->where('is_scanned', true)->count();

        // الإيراد الكلي = مجموع أسعار التذاكر المدفوعة
        // (أبسط شيء: price ثابت من event * عدد التذاكر المدفوعة)
        $totalRevenue = $paidTickets * (float) $event->price;

        // عدد المتطوعين المقبولين / الكل
        $totalVolunteers = VolunteerRequest::where('event_id', $event->id)->count();
        $approvedVolunteers = VolunteerRequest::where('event_id', $event->id)
            ->where('status', 'approved')
            ->count();

        return response()->json([
            'event' => [
                'id'         => $event->id,
                'name'       => $event->name,
                'city'       => $event->city,
                'location'   => $event->location,
                'start_time' => $event->start_time,
                'end_time'   => $event->end_time,
            ],

            'tickets' => [
                'total'      => $totalTickets,
                'paid'       => $paidTickets,
                'pending'    => $pendingTickets,
                'cancelled'  => $cancelledTickets,
                'scanned'    => $scannedTickets,
            ],

            'revenue' => [
                'currency' => config('services.stripe.currency', 'usd'),
                'total'    => $totalRevenue,
            ],

            'volunteers' => [
                'total'     => $totalVolunteers,
                'approved'  => $approvedVolunteers,
            ],
        ]);
    }

    /**
     * قائمة تذاكر حدث معيّن (للمنظم).
     * GET /api/organizer/events/{event}/tickets
     */
    public function tickets(Request $request, Event $event)
    {
        $user = $request->user();

        if (!$user || !$user->role || $user->role->name !== 'organizer' || $event->organizer_id !== $user->id) {
            return response()->json([
                'message' => 'You are not allowed to view tickets for this event.',
            ], 403);
        }

        $tickets = Ticket::with('user')
            ->where('event_id', $event->id)
            ->orderBy('created_at', 'desc')
            ->get();

        $data = $tickets->map(function (Ticket $ticket) {
            return [
                'id'             => $ticket->id,
                'qr_code'        => $ticket->qr_code,
                'payment_status' => $ticket->payment_status,
                'is_scanned'     => $ticket->is_scanned,
                'scanned_at'     => $ticket->scanned_at,
                'created_at'     => $ticket->created_at,
                'user' => [
                    'id'    => $ticket->user->id,
                    'name'  => $ticket->user->name,
                    'email' => $ticket->user->email,
                ],
            ];
        });

        return response()->json($data);
    }
}