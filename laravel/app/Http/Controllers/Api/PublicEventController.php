<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;

class PublicEventController extends Controller
{
    protected function computeIsLive(Event $event): bool
    {
        if (!$event->start_time || !$event->end_time) {
            return false;
        }

        $now = now();

        return $now->greaterThanOrEqualTo($event->start_time)
            && $now->lessThanOrEqualTo($event->end_time);
    }

    public function index(Request $request)
    {
        $query = Event::query()
            ->where('status', 'published') // ✅ مهم
            ->whereDate('start_time', '>=', now()->startOfDay());

        if ($search = $request->input('search')) {
            $query->where('name', 'ILIKE', '%' . $search . '%');
        }

        if ($city = $request->input('city')) {
            $query->where('city', 'ILIKE', '%' . $city . '%');
        }

        if ($request->filled('min_price')) {
            $query->where('price', '>=', $request->input('min_price'));
        }
        if ($request->filled('max_price')) {
            $query->where('price', '<=', $request->input('max_price'));
        }

        $events = $query->orderBy('start_time', 'asc')->get();

        $cards = $events->map(function (Event $event) {
            return [
                'id'         => $event->id,
                'name'       => $event->name,
                'city'       => $event->city,
                'price'      => $event->price,
                'picture'    => $event->picture,
                'start_time' => $event->start_time,
                'end_time'   => $event->end_time,
                'is_live'    => $this->computeIsLive($event),
            ];
        });

        return response()->json($cards);
    }

    public function show(Event $event)
    {
        //  ما نطلع draft للناس
        if ($event->status !== 'published') {
            return response()->json(['message' => 'Event not found.'], 404);
        }

        $event->load([
            'organizer:id,name',
            'categories:id,name',
        ]);

        return response()->json([
            'id'          => $event->id,
            'name'        => $event->name,
            'description' => $event->description,
            'price'       => $event->price,

            'city'        => $event->city,
            'location'    => $event->location,
            'venue'       => $event->venue,

            'start_time'  => $event->start_time,
            'end_time'    => $event->end_time,
            'online_link' => $event->online_link,
            'picture'     => $event->picture,

            'is_live'      => $this->computeIsLive($event),
            'status'       => $event->status,
            'published_at' => $event->published_at,

            'organizer'   => $event->organizer,
            'categories'  => $event->categories,
        ]);
    }
}
