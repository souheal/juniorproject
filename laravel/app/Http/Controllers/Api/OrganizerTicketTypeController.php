<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\EventTicketType;
use Illuminate\Http\Request;

class OrganizerTicketTypeController extends Controller
{
    private function ensureOrganizerOwnsEvent(Request $request, Event $event): void
    {
        $user = $request->user();

        if (!$user || !$user->role || $user->role->name !== 'organizer' || $event->organizer_id !== $user->id) {
            abort(response()->json(['message' => 'Only the organizer owner can manage ticket types.'], 403));
        }
    }

    // GET /api/organizer/events/{event}/ticket-types
    public function index(Request $request, Event $event)
    {
        $this->ensureOrganizerOwnsEvent($request, $event);

        $types = EventTicketType::where('event_id', $event->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn($t) => [
                'id' => $t->id,
                'name' => $t->name,
                'description' => $t->description,
                'is_free' => $t->is_free,
                'currency' => $t->currency,
                'price' => $t->price,
                'quantity_total' => $t->quantity_total,
                'quantity_sold' => $t->quantity_sold,
                'quantity_available' => $t->quantity_available,
                'created_at' => $t->created_at,
            ]);

        return response()->json($types);
    }

    // POST /api/organizer/events/{event}/ticket-types
    public function store(Request $request, Event $event)
    {
        $this->ensureOrganizerOwnsEvent($request, $event);

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'is_free' => ['required', 'boolean'],
            'currency' => ['nullable', 'string', 'max:10'],
            'price' => ['nullable', 'numeric', 'min:0'],
            'quantity_total' => ['required', 'integer', 'min:1'],
        ]);

        $isFree = (bool)$data['is_free'];

        $ticketType = EventTicketType::create([
            'event_id' => $event->id,
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'is_free' => $isFree,
            'currency' => $isFree ? 'SYP' : ($data['currency'] ?? 'SYP'),
            'price' => $isFree ? 0 : (float)($data['price'] ?? 0),
            'quantity_total' => (int)$data['quantity_total'],
            'quantity_sold' => 0,
        ]);

        return response()->json([
            'message' => 'Ticket type added successfully',
            'ticket_type' => $ticketType,
        ], 201);
    }

    // DELETE /api/organizer/events/{event}/ticket-types/{ticketType}
    public function destroy(Request $request, Event $event, EventTicketType $ticketType)
    {
        $this->ensureOrganizerOwnsEvent($request, $event);

        if ($ticketType->event_id !== $event->id) {
            return response()->json(['message' => 'Ticket type does not belong to this event.'], 422);
        }

        if ($ticketType->quantity_sold > 0) {
            return response()->json([
                'message' => 'Cannot delete a ticket type that already has sold tickets.',
            ], 422);
        }

        $ticketType->delete();

        return response()->json(['message' => 'Ticket type deleted successfully']);
    }
}
