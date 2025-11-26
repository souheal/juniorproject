<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;

class PublicEventController extends Controller
{
    /**
     * هل الحدث شغال حالياً حسب الوقت؟
     */
    protected function computeIsLive(Event $event): bool
    {
        if (!$event->start_time || !$event->end_time) {
            return false;
        }

        $now = now();

        return $now->greaterThanOrEqualTo($event->start_time)
            && $now->lessThanOrEqualTo($event->end_time);
    }

    // ======================
    // Public browse endpoint (cards for user)
    // ======================
    public function index(Request $request)
    {
        $query = Event::query()
            // تقدر تخليها بس published لو حبيت:
            // ->where('status', 'published')
            ->whereDate('start_time', '>=', now()->startOfDay());

        // 🔎 search بالاسم (جزئي)
        if ($search = $request->input('search')) {
            $query->where('name', 'ILIKE', '%' . $search . '%');
        }

        // city (اختياري)
        if ($city = $request->input('city')) {
            $query->where('city', 'ILIKE', '%' . $city . '%');
        }

        // price range (اختياري)
        if ($request->filled('min_price')) {
            $query->where('price', '>=', $request->input('min_price'));
        }
        if ($request->filled('max_price')) {
            $query->where('price', '<=', $request->input('max_price'));
        }

        $events = $query->orderBy('start_time', 'asc')->get();

        // نحولها لـ "كروت"
        $cards = $events->map(function (Event $event) {
            return [
                'id'      => $event->id,
                'name'    => $event->name,
                'city'    => $event->city,
                'price'   => $event->price,
                'picture' => $event->picture,
                'is_live' => $this->computeIsLive($event),
            ];
        });

        return response()->json($cards);
    }

    // ======================
    // Public event details
    // ======================
    public function show(Event $event)
    {
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
