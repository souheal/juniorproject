<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\VolunteerRequest;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class OrganizerEventStatsController extends Controller
{
    /**
     * Dashboard لارقام حدث معيّن (خاص بالمنظم صاحب الحدث).
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


 //Export ticket holders (registrations) for an event as CSV.

public function exportRegistrations(Request $request, $eventId)
{
    $organizer = $request->user();

    // Ownership check: organizer can only export their own event
    $event = Event::findOrFail($eventId);

    if ((int) $event->organizer_id !== (int) $organizer->id) {
        return response()->json([
            'message' => 'You can only export registrations for your own events.',
        ], 403);
    }

    $data = $request->validate([
        'payment_status' => ['nullable', 'in:pending,paid,cancelled'],
        'scanned'        => ['nullable', 'in:0,1'],
        'from'           => ['nullable', 'date'],
        'to'             => ['nullable', 'date'],
    ]);

    $query = Ticket::query()
        ->where('event_id', $event->id)
        ->with([
            'user:id,name,email',
            'event:id,name,start_time,end_time,location,venue,organizer_id',
        ])
        ->orderByDesc('created_at');

    // If organizer does not specify payment_status, export only PAID tickets
    if (!isset($data['payment_status'])) {
        $query->where('payment_status', 'paid');
    } else {
        $query->where('payment_status', $data['payment_status']);
    }

    // Filter scanned tickets if requested
    if (isset($data['scanned'])) {
        $query->where('is_scanned', (bool) ((int) $data['scanned']));
    }

    // Date range filter by ticket creation date
    if (!empty($data['from'])) {
        $query->whereDate('created_at', '>=', $data['from']);
    }
    if (!empty($data['to'])) {
        $query->whereDate('created_at', '<=', $data['to']);
    }

    $filename = 'event_'.$event->id.'_registrations_' . now()->format('Y-m-d_H-i-s') . '.csv';

    return new StreamedResponse(function () use ($query, $event) {
        $handle = fopen('php://output', 'w');

        // UTF-8 BOM for Excel
        fprintf($handle, chr(0xEF).chr(0xBB).chr(0xBF));

        // Header row
        fputcsv($handle, [
            'Ticket ID',
            'Event ID',
            'Event Name',
            'Event Start',
            'Event End',
            'Location',
            'Venue',
            'User ID',
            'User Name',
            'User Email',
            'Payment Status',
            'Is Scanned',
            'Scanned At',
            'QR Code',
            'Created At',
        ]);

        $query->chunk(500, function ($tickets) use ($handle) {
            foreach ($tickets as $t) {
                fputcsv($handle, [
                    $t->id,
                    $t->event_id,
                    optional($t->event)->name,
                    optional($t->event)->start_time,
                    optional($t->event)->end_time,
                    optional($t->event)->location,
                    optional($t->event)->venue,
                    $t->user_id,
                    optional($t->user)->name,
                    optional($t->user)->email,
                    $t->payment_status,
                    $t->is_scanned ? 'YES' : 'NO',
                    $t->scanned_at,
                    $t->qr_code,
                    $t->created_at?->toDateTimeString(),
                ]);
            }
        });

        fclose($handle);
    }, 200, [
        'Content-Type' => 'text/csv; charset=UTF-8',
        'Content-Disposition' => 'attachment; filename="'.$filename.'"',
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