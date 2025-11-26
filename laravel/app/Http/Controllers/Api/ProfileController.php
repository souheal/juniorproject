<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\OrganizerRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    /**
     * GET /api/profile
     * Returns header data, stats, and account-type info.
     */
    public function show(Request $request)
    {
        $user = $request->user()->load('role');

        // Stats
// All tickets for this user
$ticketsQuery = Ticket::where('user_id', $user->id);

// Count ALL tickets (no status column in your DB)
$ticketsCount = (clone $ticketsQuery)->count();

// Count distinct events that the user has tickets for
$eventsCount = (clone $ticketsQuery)
    ->distinct('event_id')
    ->count('event_id');


        $savedCount = $user->savedEvents()->count();

        // Organizer / account type info
        $latestOrganizerRequest = OrganizerRequest::where('user_id', $user->id)
            ->latest()
            ->first();

        $accountType = $user->role ? $user->role->name : 'user';

        $organizerStatus = $latestOrganizerRequest
            ? $latestOrganizerRequest->status
            : null;

        $canApplyForOrganizer =
            $accountType === 'user' &&
            (! $latestOrganizerRequest || $latestOrganizerRequest->status === 'rejected');

        return response()->json([
            'user' => [
                'id'                    => $user->id,
                'name'                  => $user->name,
                'email'                 => $user->email,
                'phone'                 => $user->phone,
                'location'              => $user->location,
                'picture'               => $user->picture
                    ? asset('storage/' . $user->picture)
                    : null,
                'email_verified'        => ! is_null($user->email_verified_at),
                'notifications_enabled' => (bool) $user->notifications_enabled,
                'account_type'          => $accountType, // "user", "organizer", "admin"
            ],
            'stats' => [
                'events'  => $eventsCount,
                'tickets' => $ticketsCount,
                'saved'   => $savedCount,
            ],
            'account_type' => [
                'current_type'            => $accountType,
                'latest_request_status'   => $organizerStatus,   // pending/approved/rejected/null
                'can_apply_for_organizer' => $canApplyForOrganizer,
            ],
        ]);
    }

    /**
     * PUT /api/profile
     * Edit profile (not password).
     */
    public function update(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'name'     => 'sometimes|string|max:255',
            'phone'    => 'sometimes|string|max:50',
            'location' => 'sometimes|string|max:255',
            'picture'  => 'sometimes|nullable|string', // base64 image
        ]);

        if (array_key_exists('picture', $data) && $data['picture']) {
            $user->picture = $this->storeBase64Image($data['picture'], 'users');
        }

        unset($data['picture']);

        $user->fill($data);
        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user'    => $user->fresh(),
        ]);
    }

    /**
     * POST /api/profile/change-password
     * Change password inside profile.
     */
    public function changePassword(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'current_password'      => 'required|string',
            'new_password'          => 'required|string|min:8|confirmed',
            // needs new_password_confirmation
        ]);

        if (! Hash::check($data['current_password'], $user->password)) {
            return response()->json([
                'message' => 'Current password is incorrect.',
            ], 422);
        }

        $user->password = Hash::make($data['new_password']);
        $user->save();

        // Optional: revoke other tokens
        if (method_exists($user, 'tokens')) {
            $currentTokenId = $request->user()->currentAccessToken()->id ?? null;
            $user->tokens()
                ->when($currentTokenId, fn ($q) => $q->where('id', '!=', $currentTokenId))
                ->delete();
        }

        return response()->json([
            'message' => 'Password updated successfully.',
        ]);
    }

    /**
     * GET /api/profile/tickets
     */
    public function tickets(Request $request)
    {
        $user = $request->user();

        $tickets = Ticket::with('event')
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'tickets' => $tickets,
        ]);
    }

    /**
     * GET /api/profile/saved-events
     */
    public function savedEvents(Request $request)
    {
        $user = $request->user();

        $events = $user->savedEvents()
            ->with('categories', 'organizer') // adjust if names differ
            ->orderByDesc('saved_events.created_at')
            ->get();

        return response()->json([
            'events' => $events,
        ]);
    }

    /**
     * POST /api/events/{event}/save
     */
    public function saveEvent(Request $request, Event $event)
    {
        $user = $request->user();

        $user->savedEvents()->syncWithoutDetaching([$event->id]);

        return response()->json([
            'message' => 'Event saved.',
        ], 201);
    }

    /**
     * DELETE /api/events/{event}/save
     */
    public function unsaveEvent(Request $request, Event $event)
    {
        $user = $request->user();

        $user->savedEvents()->detach($event->id);

        return response()->json([
            'message' => 'Event removed from saved list.',
        ]);
    }

    /**
     * POST /api/profile/notifications
     * Toggle notifications switch.
     */
    public function updateNotifications(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'enabled' => 'required|boolean',
        ]);

        $user->notifications_enabled = $data['enabled'];
        $user->save();

        return response()->json([
            'message'               => 'Notification preference updated.',
            'notifications_enabled' => (bool) $user->notifications_enabled,
        ]);
    }

    /**
     * DELETE /api/profile
     * Delete account.
     */
    public function deleteAccount(Request $request)
    {
        $user = $request->user();

        if (method_exists($user, 'tokens')) {
            $user->tokens()->delete();
        }

        $user->delete();

        return response()->json([
            'message' => 'Account deleted successfully.',
        ]);
    }

    /**
     * Helper for base64 images.
     */
    protected function storeBase64Image(string $base64, string $folder): string
    {
        if (preg_match('/^data:image\/(\w+);base64,/', $base64, $type)) {
            $base64 = substr($base64, strpos($base64, ',') + 1);
            $extension = strtolower($type[1]) === 'jpeg' ? 'jpg' : $type[1];
        } else {
            $extension = 'png';
        }

        $binary = base64_decode($base64, true);

        if ($binary === false) {
            abort(422, 'Invalid image data.');
        }

        $fileName = $folder . '/' . uniqid('', true) . '.' . $extension;

        Storage::disk('public')->put($fileName, $binary);

        return $fileName;
    }
}
