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
    public function show(Request $request)
    {
        $user = $request->user()->load('role');

        $ticketsQuery = Ticket::where('user_id', $user->id);

        $ticketsCount = (clone $ticketsQuery)->count();

        $eventsCount = (clone $ticketsQuery)
            ->distinct('event_id')
            ->count('event_id');

        $savedCount = $user->savedEvents()->count();

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
                'account_type'          => $accountType,
            ],
            'stats' => [
                'events'  => $eventsCount,
                'tickets' => $ticketsCount,
                'saved'   => $savedCount,
            ],
            'account_type' => [
                'current_type'            => $accountType,
                'latest_request_status'   => $organizerStatus,
                'can_apply_for_organizer' => $canApplyForOrganizer,
            ],
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'name'     => 'sometimes|string|max:255',
            'phone'    => 'sometimes|string|max:50',
            'location' => 'sometimes|string|max:255',
            'picture'  => 'sometimes|nullable|string',
        ]);

        //  حذف القديمة قبل تخزين الجديدة
        if (array_key_exists('picture', $data)) {
            if ($data['picture']) {
                if ($user->picture && Storage::disk('public')->exists($user->picture)) {
                    Storage::disk('public')->delete($user->picture);
                }
                $user->picture = $this->storeBase64Image($data['picture'], 'users');
            } else {
                // إذا بعت null يعني حذف الصورة
                if ($user->picture && Storage::disk('public')->exists($user->picture)) {
                    Storage::disk('public')->delete($user->picture);
                }
                $user->picture = null;
            }
        }

        unset($data['picture']);

        $user->fill($data);
        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user'    => $user->fresh(),
        ]);
    }

    public function changePassword(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'current_password'      => 'required|string',
            'new_password'          => 'required|string|min:8|confirmed',
        ]);

        if (! Hash::check($data['current_password'], $user->password)) {
            return response()->json([
                'message' => 'Current password is incorrect.',
            ], 422);
        }

        $user->password = Hash::make($data['new_password']);
        $user->save();

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

    public function savedEvents(Request $request)
    {
        $user = $request->user();

        $events = $user->savedEvents()
            ->with('categories', 'organizer')
            ->orderByDesc('saved_events.created_at')
            ->get();

        return response()->json([
            'events' => $events,
        ]);
    }

    public function saveEvent(Request $request, Event $event)
    {
        $user = $request->user();

        $user->savedEvents()->syncWithoutDetaching([$event->id]);

        return response()->json([
            'message' => 'Event saved.',
        ], 201);
    }

    public function unsaveEvent(Request $request, Event $event)
    {
        $user = $request->user();

        $user->savedEvents()->detach($event->id);

        return response()->json([
            'message' => 'Event removed from saved list.',
        ]);
    }

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

    public function deleteAccount(Request $request)
    {
        $user = $request->user();

        if (method_exists($user, 'tokens')) {
            $user->tokens()->delete();
        }

        // حذف صورة البروفايل من الستوريج
        if ($user->picture && Storage::disk('public')->exists($user->picture)) {
            Storage::disk('public')->delete($user->picture);
        }

        $user->delete();

        return response()->json([
            'message' => 'Account deleted successfully.',
        ]);
    }

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
