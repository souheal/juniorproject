<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Carbon\Carbon;

class EventController extends Controller
{
    // =========================
    // Helpers
    // =========================

    protected function requireOrganizer(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->role || $user->role->name !== 'organizer') {
            abort(response()->json([
                'message' => 'Only organizers can create or update events',
            ], 403));
        }

        return $user;
    }

    protected function requireAdmin(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->role || $user->role->name !== 'admin') {
            abort(response()->json([
                'message' => 'Only admin can delete events',
            ], 403));
        }

        return $user;
    }

    // =========================
    // Organizer side
    // =========================

    // قائمة أحداث المنظّم نفسه
    public function index(Request $request)
    {
        $organizer = $this->requireOrganizer($request);

        $events = Event::where('organizer_id', $organizer->id)
            ->orderByDesc('start_time')
            ->get();

        return response()->json($events);
    }

    // إنشاء event جديد (organizer only)
    public function store(Request $request)
    {
        $organizer = $this->requireOrganizer($request);

        $data = $request->validate([
            'name'        => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'start_time'  => ['required', 'date'],
            'end_time'    => ['required', 'date', 'after:start_time'],
            'location'    => ['required', 'string', 'max:255'],
            'capacity'    => ['required', 'integer', 'min:1'],
            'price'       => ['required', 'numeric', 'min:0'],
            'online_link' => ['nullable', 'string', 'max:500'],
            'picture'     => ['nullable', 'string'], // base64

            // 👇 جديد: الكاتيجوريز (IDs من جدول categories)
            'categories'   => ['nullable', 'array'],
            'categories.*' => ['integer', 'exists:categories,id'],
        ]);

        $picturePath = null;

        if (! empty($data['picture'])) {
            $binary = base64_decode($data['picture']);
            if ($binary !== false) {
                $filename = 'event_' . Str::uuid()->toString() . '.jpg';
                $path = 'events/' . $filename;
                Storage::disk('public')->put($path, $binary);
                $picturePath = $path;
            }
        }

        $event = Event::create([
            'organizer_id' => $organizer->id,
            'name'         => $data['name'],
            'description'  => $data['description'],
            'start_time'   => $data['start_time'],
            'end_time'     => $data['end_time'],
            'location'     => $data['location'],
            'capacity'     => $data['capacity'],
            'price'        => $data['price'],
            'online_link'  => $data['online_link'] ?? null,
            'picture'      => $picturePath,
        ]);

        // 👈 ربط الحدث مع الكاتيجوريز في جدول category_event
        if (! empty($data['categories'])) {
            $event->categories()->sync($data['categories']);
        }

        return response()->json([
            'message' => 'Event created successfully',
            'event'   => $event->load('categories:id,name'),
        ], 201);
    }

    // تعديل event (organizer فقط، ولازم يكون صاحب الحدث)
    public function update(Request $request, $id)
    {
        $organizer = $this->requireOrganizer($request);

        $event = Event::findOrFail($id);

        if ($event->organizer_id !== $organizer->id) {
            return response()->json([
                'message' => 'You can only update your own events',
            ], 403);
        }

        $data = $request->validate([
            'name'        => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'string'],
            'start_time'  => ['sometimes', 'date'],
            'end_time'    => ['sometimes', 'date'],
            'location'    => ['sometimes', 'string', 'max:255'],
            'capacity'    => ['sometimes', 'integer', 'min:1'],
            'price'       => ['sometimes', 'numeric', 'min:0'],
            'online_link' => ['sometimes', 'nullable', 'string', 'max:500'],
            'picture'     => ['sometimes', 'nullable', 'string'], // base64

            // 👇 جديد: تحديث الكاتيجوريز
            'categories'   => ['sometimes', 'array'],
            'categories.*' => ['integer', 'exists:categories,id'],
        ]);

        // صورة جديدة لو انبعت
        if (array_key_exists('picture', $data)) {
            if ($data['picture']) {
                $binary = base64_decode($data['picture']);
                if ($binary !== false) {
                    $filename = 'event_' . Str::uuid()->toString() . '.jpg';
                    $path = 'events/' . $filename;
                    Storage::disk('public')->put($path, $binary);
                    $data['picture'] = $path;
                } else {
                    unset($data['picture']);
                }
            } else {
                $data['picture'] = null;
            }
        }

        $original = $event->getOriginal();
        $event->fill($data);
        $event->save();

        // 👈 لو بعت categories حتى لو مصفوفة فاضية، نعمل sync
        if (array_key_exists('categories', $data)) {
            $event->categories()->sync($data['categories'] ?? []);
        }

        // حقول لو تغيرت نرسل إشعارات (لسه ما أضفت categories هنا)
        $watchedFields = ['capacity', 'description', 'start_time', 'end_time', 'picture'];
        $changedFields = [];

        foreach ($watchedFields as $field) {
            if (array_key_exists($field, $event->getChanges())) {
                $changedFields[] = $field;
            }
        }

        if (! empty($changedFields)) {
            $this->notifyEventUpdated($event, $changedFields);
        }

        return response()->json([
            'message'        => 'Event updated successfully',
            'event'          => $event->load('categories:id,name'),
            'changed_fields' => $changedFields,
        ]);
    }

    // =========================
    // Admin side (delete فقط)
    // =========================

    public function destroy(Request $request, $id)
    {
        $this->requireAdmin($request);

        $event = Event::findOrFail($id);

        // إشعار إلغاء قبل الحذف
        $this->notifyEventCancelled($event);

        $event->delete();

        return response()->json([
            'message' => 'Event deleted and users notified (if they had tickets)',
        ]);
    }

    // =========================
    // Notifications helpers
    // =========================

    protected function notifyEventUpdated(Event $event, array $changedFields)
    {
        $tickets = Ticket::where('event_id', $event->id)->with('user')->get();

        if ($tickets->isEmpty()) {
            return;
        }

        $fieldLabels = [
            'capacity'    => 'capacity',
            'description' => 'description',
            'start_time'  => 'start time',
            'end_time'    => 'end time',
            'picture'     => 'picture',
        ];

        $labels      = array_map(fn ($f) => $fieldLabels[$f] ?? $f, $changedFields);
        $changedText = implode(', ', $labels);

        foreach ($tickets as $ticket) {
            if (! $ticket->user) {
                continue;
            }

            Notification::create([
                'user_id'     => $ticket->user_id,
                'event_id'    => $event->id,
                'type'        => 'event_updated',
                'content'     => 'Event "' . $event->name . '" has been updated: ' . $changedText,
                'read_status' => false,
            ]);
        }
    }

    protected function notifyEventCancelled(Event $event)
    {
        $tickets = Ticket::where('event_id', $event->id)->with('user')->get();

        foreach ($tickets as $ticket) {
            if (! $ticket->user) {
                continue;
            }

            Notification::create([
                'user_id'     => $ticket->user_id,
                'event_id'    => $event->id,
                'type'        => 'event_cancelled',
                'content'     => 'Event "' . $event->name . '" has been cancelled.',
                'read_status' => false,
            ]);
        }
    }

    // =========================
    // Public / User side: Browse events with filters
    // =========================
    public function browse(Request $request)
    {
        $query = Event::query()
            ->with([
                'organizer:id,name',
                'categories:id,name',
            ])
            ->orderBy('start_time');

        // ----- Location filter (LIKE) -----
        if ($request->filled('location')) {
            $location = $request->input('location');
            $query->where('location', 'ILIKE', '%' . $location . '%');
        }

        // ----- Category filter (IDs) -----
        $categoryIds = $request->input('category_ids');
        if (is_array($categoryIds) && ! empty($categoryIds)) {
            $query->whereHas('categories', function ($q) use ($categoryIds) {
                $q->whereIn('categories.id', $categoryIds);
            });
        }

        // ----- Price filter -----
        if ($request->filled('min_price')) {
            $query->where('price', '>=', $request->input('min_price'));
        }

        if ($request->filled('max_price')) {
            $query->where('price', '<=', $request->input('max_price'));
        }

        // ----- Date filter: anytime / today / tomorrow / this_week / this_month -----
        $filter = $request->input('date_filter', 'anytime');

        $now        = Carbon::now();
        $todayStart = $now->copy()->startOfDay();
        $todayEnd   = $now->copy()->endOfDay();

        switch ($filter) {
            case 'today':
                $query->whereBetween('start_time', [$todayStart, $todayEnd]);
                break;

            case 'tomorrow':
                $start = $todayStart->copy()->addDay();
                $end   = $todayEnd->copy()->addDay();
                $query->whereBetween('start_time', [$start, $end]);
                break;

            case 'this_week':
                $start = $todayStart;
                $end   = $now->copy()->endOfWeek();
                $query->whereBetween('start_time', [$start, $end]);
                break;

            case 'this_month':
                $start = $todayStart;
                $end   = $now->copy()->endOfMonth();
                $query->whereBetween('start_time', [$start, $end]);
                break;

            case 'anytime':
            default:
                $query->where('start_time', '>=', $now);
                break;
        }

        $events = $query->get();

        return response()->json($events);
    }
}
