<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Category;
use App\Models\Ticket;
use App\Models\VolunteerRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ManageEventController extends Controller
{
    /**
     * Helper: ensure the current user is an organizer.
     */
    protected function requireOrganizer(Request $request)
    {
        $user = $request->user();

        if (!$user || !$user->role || $user->role->name !== 'organizer') {
            abort(response()->json([
                'message' => 'Only organizers can perform this action.',
            ], 403));
        }

        return $user;
    }

    /**
     * Helper: ensure the current user is an admin.
     */
    protected function requireAdmin(Request $request)
    {
        $user = $request->user();

        if (!$user || !$user->role || $user->role->name !== 'admin') {
            abort(response()->json([
                'message' => 'Only admins can perform this action.',
            ], 403));
        }

        return $user;
    }

    //is the event live or not
    protected function computeIsLive(Event $event): bool
    {
        if (!$event->start_time || !$event->end_time) {
            return false;
        }

        $now = now();

        return $now->greaterThanOrEqualTo($event->start_time)
            && $now->lessThanOrEqualTo($event->end_time);
    }

    /**
     * is_live (time-based) + full_location.
     */
    protected function addLocationAndLiveInfo(Event $event): void
    {
        $event->is_live = $this->computeIsLive($event);

        // Combine city + location
        $pieces = array_filter([
            $event->city,
            $event->location,
        ], fn ($v) => !is_null($v) && $v !== '');

        $event->full_location = implode(' - ', $pieces);
    }

    /**
     * Apply addLocationAndLiveInfo on a model
     */
    protected function transformEvents($events)
    {
        if ($events instanceof \Illuminate\Pagination\AbstractPaginator) {
            $events->getCollection()->transform(function (Event $event) {
                $this->addLocationAndLiveInfo($event);
                return $event;
            });
        } elseif ($events instanceof \Illuminate\Support\Collection) {
            $events->transform(function (Event $event) {
                $this->addLocationAndLiveInfo($event);
                return $event;
            });
        } elseif ($events instanceof Event) {
            $this->addLocationAndLiveInfo($events);
        }

        return $events;
    }

    // =========================
    // Admin / Organizer listing
    // =========================
    public function index(Request $request)
    {
        $user = $request->user();

        $query = Event::with(['organizer:id,name', 'categories:id,name']);

        // organizer يشوف بس أحداثه
        if ($user && $user->role && $user->role->name === 'organizer') {
            $query->where('organizer_id', $user->id);
        }

        // Filter by status (published/draft) باستخدام حقل status
        $status = $request->input('status');
        if ($status === 'published') {
            $query->where('status', 'published');
        } elseif ($status === 'draft') {
            $query->where('status', 'draft');
        }

        // Date range filter
        if ($request->filled('date_from')) {
            $query->whereDate('start_time', '>=', $request->input('date_from'));
        }
        if ($request->filled('date_to')) {
            $query->whereDate('start_time', '<=', $request->input('date_to'));
        }

        // Search by name or location pieces
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ILIKE', '%' . $search . '%')
                  ->orWhere('city', 'ILIKE', '%' . $search . '%')
                  ->orWhere('location', 'ILIKE', '%' . $search . '%')
                  ->orWhere('venue', 'ILIKE', '%' . $search . '%');
            });
        }

        $events = $query
            ->orderBy('start_time', 'asc')
            ->paginate($request->integer('per_page', 10));

        $events = $this->transformEvents($events);

        return response()->json($events);
    }

    // ============ Create event ============
    public function store(Request $request)
    {
        $organizer = $this->requireOrganizer($request);

        $data = $request->validate([
            'name'        => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],

            'start_time'  => ['required', 'date', 'after:now'],
            'end_time'    => ['required', 'date', 'after:start_time'],

            'city'        => ['required', 'string', 'max:255'],
            'location'    => ['required', 'string', 'max:255'],
            'venue'       => ['nullable', 'string', 'max:255'],

            'capacity'    => ['required', 'integer', 'min:1'],
            'price'       => ['required', 'numeric', 'min:0'],

            'online_link' => ['nullable', 'url'],
            'picture'     => ['nullable', 'string'],
            'volunteer_needs' => ['nullable', 'array'],

            'categories'   => ['required', 'array', 'min:1'],
            'categories.*' => ['integer', 'exists:categories,id'],
        ]);

        $picturePath = null;
        if (!empty($data['picture'])) {
            $picturePath = $this->saveBase64Image($data['picture'], 'events');
        }

        $event = Event::create([
            'organizer_id' => $organizer->id,
            'name'         => $data['name'],
            'description'  => $data['description'],
            'start_time'   => $data['start_time'],
            'end_time'     => $data['end_time'],
            'city'         => $data['city'],
            'location'     => $data['location'],
            'venue'        => $data['venue'] ?? null,
            'capacity'     => $data['capacity'],
            'price'        => $data['price'],
            'online_link'  => $data['online_link'] ?? null,
            'picture'      => $picturePath,
            'volunteer_needs' => $data['volunteer_needs'] ?? null,
            'status'       => 'draft',
            'published_at' => null,
            'is_live'      => false,
        ]);

        $event->categories()->sync($data['categories']);

        $this->addLocationAndLiveInfo($event);

        return response()->json([
            'message' => 'Event created successfully.',
            'event'   => $event,
        ], 201);
    }

    // ============ Update event ============
    public function update(Request $request, $id)
    {
        $user  = $request->user();
        $event = Event::with('categories')->findOrFail($id);

        // organizer صاحب الحدث أو admin
        if (
            !$user ||
            !$user->role ||
            !(
                ($user->role->name === 'admin') ||
                ($user->role->name === 'organizer' && $event->organizer_id == $user->id)
            )
        ) {
            return response()->json([
                'message' => 'You are not allowed to update this event.',
            ], 403);
        }

        $data = $request->validate([
            'name'        => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'string'],

            'start_time'  => ['sometimes', 'date', 'after:now'],
            'end_time'    => ['sometimes', 'date', 'after:start_time'],

            'city'        => ['sometimes', 'string', 'max:255'],
            'location'    => ['sometimes', 'string', 'max:255'],
            'venue'       => ['sometimes', 'nullable', 'string', 'max:255'],

            'capacity'    => ['sometimes', 'integer', 'min:1'],
            'price'       => ['sometimes', 'numeric', 'min:0'],

            'online_link' => ['sometimes', 'nullable', 'url'],
            'picture'     => ['sometimes', 'nullable', 'string'],
            'volunteer_needs' => ['sometimes', 'nullable', 'array'],


            'categories'   => ['sometimes', 'array'],
            'categories.*' => ['integer', 'exists:categories,id'],

            'status'       => ['sometimes', 'string', 'in:draft,published'],
        ]);

        $event->fill($data);

        // صورة جديدة
        if (array_key_exists('picture', $data)) {
            if ($data['picture']) {
                if ($event->picture && Storage::disk('public')->exists($event->picture)) {
                    Storage::disk('public')->delete($event->picture);
                }
                $event->picture = $this->saveBase64Image($data['picture'], 'events');
            } else {
                if ($event->picture && Storage::disk('public')->exists($event->picture)) {
                    Storage::disk('public')->delete($event->picture);
                }
                $event->picture = null;
            }
        }

        // لو تم نشر الحدث لأول مرة
        if (isset($data['status']) && $data['status'] === 'published' && !$event->published_at) {
            $event->published_at = now();
        }

        $event->save();

        if (isset($data['categories'])) {
            $event->categories()->sync($data['categories']);
        }

        $this->addLocationAndLiveInfo($event);

        return response()->json([
            'message' => 'Event updated successfully.',
            'event'   => $event,
        ]);
    }

    // ============ Delete event (Admin only) ============
    public function destroy(Request $request, $id)
    {
        //  الأدمن فقط
        $this->requireAdmin($request);

        $event = Event::findOrFail($id);

        $hasTickets    = Ticket::where('event_id', $event->id)->exists();
        $hasVolunteers = VolunteerRequest::where('event_id', $event->id)->exists();

        if ($hasTickets || $hasVolunteers) {
            return response()->json([
                'message' => 'Cannot delete event that has tickets or volunteers.',
            ], 422);
        }

        if ($event->picture && Storage::disk('public')->exists($event->picture)) {
            Storage::disk('public')->delete($event->picture);
        }

        $event->categories()->detach();
        $event->delete();

        return response()->json([
            'message' => 'Event deleted successfully by admin.',
        ]);
    }

    // =================
    // Helper: save image
    // =================
    protected function saveBase64Image(string $base64, string $folder): string
    {
        if (!str_starts_with($base64, 'data:image')) {
            throw new \InvalidArgumentException('Invalid image data.');
        }

        [$header, $encoded] = explode(',', $base64, 2);

        if (preg_match('/data:image\/(\w+);base64/', $header, $matches)) {
            $extension = strtolower($matches[1]);
        } else {
            $extension = 'jpg';
        }

        $binary = base64_decode($encoded);

        if ($binary === false) {
            throw new \RuntimeException('Failed to decode base64 image.');
        }

        $fileName = $folder . '/' . Str::uuid()->toString() . '.' . $extension;

        Storage::disk('public')->put($fileName, $binary);

        return $fileName;
    }
}
