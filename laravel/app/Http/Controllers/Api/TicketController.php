<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ticket;
use Illuminate\Http\Request;

class TicketController extends Controller
{
    /**
     * تذاكر اليوزر الحالي
     */
    public function myTickets(Request $request)
    {
        $user = $request->user();

        $tickets = Ticket::with('event')
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get();

        $data = $tickets->map(function (Ticket $ticket) {
            return [
                'id'             => $ticket->id,
                'qr_code'        => $ticket->qr_code,
                'payment_status' => $ticket->payment_status,
                'is_scanned'     => $ticket->is_scanned,
                'scanned_at'     => $ticket->scanned_at,
                'event' => [
                    'id'         => $ticket->event->id,
                    'name'       => $ticket->event->name,
                    'city'       => $ticket->event->city,
                    'location'   => $ticket->event->location,
                    'start_time' => $ticket->event->start_time,
                    'end_time'   => $ticket->event->end_time,
                ],
            ];
        });

        return response()->json($data);
    }

    /**
     * مسح QR عند باب الإيفنت – مرة واحدة فقط
     * Body: { "qr_code": "...." }
     * المنظم فقط يقدر يستدعيه.
     */
    public function scan(Request $request)
    {
        $user = $request->user();

        if (!$user || !$user->role || $user->role->name !== 'organizer') {
            return response()->json(['message' => 'Only organizers can scan tickets.'], 403);
        }

        $data = $request->validate([
            'qr_code' => ['required', 'string'],
        ]);

        $ticket = Ticket::with('event')
            ->where('qr_code', $data['qr_code'])
            ->first();

        if (!$ticket) {
            return response()->json([
                'valid'   => false,
                'message' => 'Invalid QR code.',
            ], 404);
        }

        // تأكد أن المنظم صاحب الحدث
        if ($ticket->event->organizer_id !== $user->id) {
            return response()->json([
                'valid'   => false,
                'message' => 'This ticket does not belong to your event.',
            ], 403);
        }

        // لازم تكون التذكرة مدفوعة
        if ($ticket->payment_status !== 'paid') {
            return response()->json([
                'valid'   => false,
                'message' => 'Ticket is not paid.',
            ], 422);
        }

        // أهم نقطة: مسموح scan مرة واحدة فقط
        if ($ticket->is_scanned) {
            return response()->json([
                'valid'   => false,
                'message' => 'Ticket already used.',
                'scanned_at' => $ticket->scanned_at,
            ], 422);
        }

        // نعلمها مستخدمة
        $ticket->is_scanned = true;
        $ticket->scanned_at = now();
        $ticket->save();

        return response()->json([
            'valid'   => true,
            'message' => 'Ticket accepted. Welcome!',
            'event_id'=> $ticket->event_id,
        ]);
    }
}
