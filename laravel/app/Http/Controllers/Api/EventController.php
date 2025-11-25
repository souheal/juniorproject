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

class EventController extends Controller
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

    /**
     * Compute whether an event is live right now based on its start/end time.
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

    /**
     * Attach smart fields: is_live (time-based) + full_location.
     */
    protected function addLocationAndLiveInfo(Event $event): void
    {
        // Always recompute is_live from time window (ignore any client input)
        $event->is_live = $this->computeIsLive($event);

        // Combine city + location + venue for convenient display/search
        $pieces = array_filter([
            $event->city,
            $event->location,
            $event->venue,
        ], fn ($v) => !is_null($v) && $v !== '');

        $event->full_location = implode(' - ', $pieces);
    }

    /**
     * Apply addLocationAndLiveInfo on a model / collection / paginator.
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

    /**
     * Admin/Organizer events list with basic filters.
     * - Admin: sees all events.
     * - Organizer: sees only own events.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $query = Event::with(['organizer:id,name', 'categories:id,name']);

        if ($user && $user->role && $user->role->name === 'organizer') {
            $query->where('organizer_id', $user->id);
        }

        // Filter by status (published/draft)
        $status = $request->input('status');
        if ($status === 'published') {
            $query->where('is_published', true);
        } elseif ($status === 'draft') {
            $query->where('is_published', false);
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

    // ============
    // Create event
    // ============

    public function store(Request $request)
    {
        $organizer = $this->requireOrganizer($request);

        $data = $request->validate([
            'name'        => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],

            'start_time'  => ['required', 'date', 'after:now'],
            'end_time'    => ['required', 'date', 'after:start_time'],

            // NEW: city / location / venue
            'city'        => ['required', 'string', 'max:255'],
            'location'    => ['required', 'string', 'max:255'], // area/district
            'venue'       => ['nullable', 'string', 'max:255'], // building / hotel / stadium

            'capacity'    => ['required', 'integer', 'min:1'],
            'price'       => ['required', 'numeric', 'min:0'],

            'online_link' => ['nullable', 'url'],

            // Base64 image: data:image/jpeg;base64,...
            'picture'     => ['nullable', 'string'],

            // Categories (pivot: category_event)
            'categories'   => ['required', 'array', 'min:1'],
            'categories.*' => ['integer', 'exists:categories,id'],
        ]);

        // Handle base64 image (optional)
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

            // new events start as draft; you can change this logic if needed
            'is_published' => false,

            // we store some value, but in responses we always recompute from time
            'is_live'      => false,
        ]);

        // Sync categories
        $event->categories()->sync($data['categories']);

        $this->addLocationAndLiveInfo($event);

        return response()->json([
            'message' => 'Event created successfully.',
            'event'   => $event,
        ], 201);
    }

    // ============
    // Update event
    // ============

    public function update(Request $request, $id)
    {
        $user  = $request->user();
        $event = Event::with('categories')->findOrFail($id);

        // Authorization: organizer who owns it OR admin
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

            'categories'   => ['sometimes', 'array'],
            'categories.*' => ['integer', 'exists:categories,id'],

            'is_published' => ['sometimes', 'boolean'],
        ]);

        // Update simple attributes
        $event->fill($data);

        // Handle base64 image change (if provided)
        if (array_key_exists('picture', $data)) {
            if ($data['picture']) {
                // delete old file if exists
                if ($event->picture && Storage::disk('public')->exists($event->picture)) {
                    Storage::disk('public')->delete($event->picture);
                }

                $event->picture = $this->saveBase64Image($data['picture'], 'events');
            } else {
                // null picture: delete old
                if ($event->picture && Storage::disk('public')->exists($event->picture)) {
                    Storage::disk('public')->delete($event->picture);
                }
                $event->picture = null;
            }
        }

        $event->save();

        // Sync categories if provided
        if (isset($data['categories'])) {
            $event->categories()->sync($data['categories']);
        }

        $this->addLocationAndLiveInfo($event);

        return response()->json([
            'message' => 'Event updated successfully.',
            'event'   => $event,
        ]);
    }

    // ============
    // Delete event
    // ============

    public function destroy(Request $request, $id)
    {
        $user  = $request->user();
        $event = Event::findOrFail($id);

        if (
            !$user ||
            !$user->role ||
            !(
                ($user->role->name === 'admin') ||
                ($user->role->name === 'organizer' && $event->organizer_id == $user->id)
            )
        ) {
            return response()->json([
                'message' => 'You are not allowed to delete this event.',
            ], 403);
        }

        // Optional: prevent deletion if tickets or volunteer requests exist
        $hasTickets = Ticket::where('event_id', $event->id)->exists();
        $hasVolunteers = VolunteerRequest::where('event_id', $event->id)->exists();

        if ($hasTickets || $hasVolunteers) {
            return response()->json([
                'message' => 'Cannot delete event that has tickets or volunteers.',
            ], 422);
        }

        // Delete picture file if exists
        if ($event->picture && Storage::disk('public')->exists($event->picture)) {
            Storage::disk('public')->delete($event->picture);
        }

        $event->categories()->detach();
        $event->delete();

        return response()->json([
            'message' => 'Event deleted successfully.',
        ]);
    }

    // ======================
    // Public browse endpoint
    // ======================

    public function browse(Request $request)
    {
        $query = Event::with(['organizer:id,name', 'categories:id,name'])
            ->where('is_published', true)
            ->whereDate('start_time', '>=', now()->startOfDay());

        // Filter by category
        if ($categoryId = $request->input('category_id')) {
            $query->whereHas('categories', function ($q) use ($categoryId) {
                $q->where('categories.id', $categoryId);
            });
        }

        // Filter by city
        if ($city = $request->input('city')) {
            $query->where('city', 'ILIKE', '%' . $city . '%');
        }

        // Unified "place" filter: matches city OR location OR venue
        if ($place = $request->input('place')) {
            $query->where(function ($q) use ($place) {
                $q->where('city', 'ILIKE', '%' . $place . '%')
                  ->orWhere('location', 'ILIKE', '%' . $place . '%')
                  ->orWhere('venue', 'ILIKE', '%' . $place . '%');
            });
        }

        // Date filter (specific day)
        if ($date = $request->input('date')) {
            $query->whereDate('start_time', $date);
        }

        // Only currently live events (based on time)
        if ($request->boolean('live_only')) {
            $now = now();
            $query->where('start_time', '<=', $now)
                  ->where('end_time', '>=', $now);
        }

        // General search across name + all location fields
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

    // =================
    // Helper: save image
    // =================

    /**
     * Save a base64 image string (data:image/xxx;base64,...) to storage.
     * Returns the stored relative path (e.g. "events/abcdef.jpg").
     */
    protected function saveBase64Image(string $base64, string $folder): string
    {
        if (!str_starts_with($base64, 'data:image')) {
            throw new \InvalidArgumentException('Invalid image data.');
        }

        // Split header and data
        [$header, $encoded] = explode(',', $base64, 2);

        // Extract extension from header
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
