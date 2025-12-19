<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\VolunteerRequest;
use Illuminate\Http\Request;

class VolunteerOpportunitiesController extends Controller
{
    private function durationHours(Event $event): ?int
    {
        if (!$event->start_time || !$event->end_time) return null;
        $h = $event->start_time->diffInHours($event->end_time);
        return max(1, (int) $h);
    }

    private function acceptedCount(int $eventId, string $type): int
    {
        return VolunteerRequest::where('event_id', $eventId)
            ->where('volunteer_type', $type)
            ->where('status', 'accepted')
            ->count();
    }

    private function spotsLeft(Event $event, string $type, int $limit): int
    {
        $accepted = $this->acceptedCount($event->id, $type);
        $left = $limit - $accepted;
        return $left > 0 ? $left : 0;
    }

    /**
     * GET /api/volunteer/opportunities
     * يرجّع cards مثل UI
     */
    public function index(Request $request)
    {
        $events = Event::query()
            ->where('status', 'published')
            ->whereDate('start_time', '>=', now()->startOfDay())
            ->orderBy('start_time', 'asc')
            ->get();

        $out = [];

        foreach ($events as $event) {
            $needs = $event->volunteer_needs ?? [];

            // إذا ما في احتياجات متطوعين، ما نعرضه بصفحة التطوع
            if (!is_array($needs) || count($needs) === 0) continue;

            // UI عادة تعرض role واحد بالكارد، خلينا نختار أول role
            $firstType = array_key_first($needs);
            $role = $needs[$firstType] ?? null;

            if (!is_array($role)) continue;

            $limit = (int)($role['limit'] ?? 0);
            if ($limit <= 0) continue;

            $out[] = [
                'event' => [
                    'id'       => $event->id,
                    'name'     => $event->name,
                    'date'     => optional($event->start_time)->toDateString(),
                    'time'     => optional($event->start_time)->format('g:i A') . ' - ' . optional($event->end_time)->format('g:i A'),
                    'duration_hours' => $this->durationHours($event),
                    'venue'    => $event->venue,
                    'location' => $event->location,
                    'city'     => $event->city ?? null,
                    'picture'  => $event->picture,
                ],
                'role' => [
                    'type'  => $firstType,
                    'title' => (string)($role['title'] ?? $firstType),
                ],
                'spots_left' => $this->spotsLeft($event, $firstType, $limit),
            ];
        }

        return response()->json($out);
    }

    /**
     * GET /api/volunteer/opportunities/{event}
     * يرجع تفاصيل event + كل roles المطلوبة
     */
    public function showEvent(Event $event)
    {
        if ($event->status !== 'published') {
            return response()->json(['message' => 'Event not found.'], 404);
        }

        $needs = $event->volunteer_needs ?? [];
        if (!is_array($needs)) $needs = [];

        $roles = [];

        foreach ($needs as $type => $role) {
            if (!is_array($role)) continue;
            $limit = (int)($role['limit'] ?? 0);
            if ($limit <= 0) continue;

            $roles[] = [
                'type'       => $type,
                'title'      => (string)($role['title'] ?? $type),
                'spots_left' => $this->spotsLeft($event, $type, $limit),
            ];
        }

        return response()->json([
            'event' => [
                'id'          => $event->id,
                'name'        => $event->name,
                'description' => $event->description,
                'date'        => optional($event->start_time)->toDateString(),
                'start_time'  => $event->start_time,
                'end_time'    => $event->end_time,
                'duration_hours' => $this->durationHours($event),
                'venue'       => $event->venue,
                'location'    => $event->location,
                'picture'     => $event->picture,
            ],
            'roles' => $roles,
        ]);
    }

    /**
     * GET /api/volunteer/opportunities/{event}/roles/{type}
     * role details مثل requirements/benefits
     */
    public function roleDetails(Event $event, string $type)
    {
        if ($event->status !== 'published') {
            return response()->json(['message' => 'Event not found.'], 404);
        }

        $needs = $event->volunteer_needs ?? [];
        if (!is_array($needs) || !isset($needs[$type]) || !is_array($needs[$type])) {
            return response()->json(['message' => 'Invalid volunteer role type.'], 422);
        }

        $role = $needs[$type];
        $limit = (int)($role['limit'] ?? 0);

        return response()->json([
            'event' => [
                'id'       => $event->id,
                'name'     => $event->name,
                'date'     => optional($event->start_time)->toDateString(),
                'venue'    => $event->venue,
                'location' => $event->location,
                'picture'  => $event->picture,
            ],
            'role' => [
                'type'         => $type,
                'title'        => (string)($role['title'] ?? $type),
                'description'  => (string)($role['description'] ?? ''),
                'requirements' => (array)($role['requirements'] ?? []),
                'benefits'     => (array)($role['benefits'] ?? []),
                'limit'        => $limit,
                'spots_left'   => $limit > 0 ? $this->spotsLeft($event, $type, $limit) : 0,
            ],
        ]);
    }
}
