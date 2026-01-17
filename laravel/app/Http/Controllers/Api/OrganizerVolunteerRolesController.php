<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Illuminate\Http\Request;

class OrganizerVolunteerRolesController extends Controller
{
    private function requireOrganizerOwner(Request $request, Event $event)
    {
        $user = $request->user();

        if (!$user || !$user->role || $user->role->name !== 'organizer') {
            abort(response()->json(['message' => 'Only organizers can perform this action.'], 403));
        }

        if ((int)$event->organizer_id !== (int)$user->id) {
            abort(response()->json(['message' => 'You are not the owner of this event.'], 403));
        }

        return $user;
    }

    // GET /api/organizer/events/{event}/volunteer-roles
    public function index(Request $request, Event $event)
    {
        $this->requireOrganizerOwner($request, $event);
        return response()->json($event->volunteer_needs ?? []);
    }

    // POST /api/organizer/events/{event}/volunteer-roles
    public function store(Request $request, Event $event)
    {
        $this->requireOrganizerOwner($request, $event);

        $data = $request->validate([
            'role_name'     => ['required', 'string', 'max:255'],
            'spots'         => ['required', 'integer', 'min:1'],
            'start_time'    => ['nullable', 'date'],
            'end_time'      => ['nullable', 'date', 'after_or_equal:start_time'],
            'requirements'  => ['nullable', 'string', 'max:2000'],
            'benefits'      => ['nullable', 'string', 'max:2000'],
        ]);

        $roles = $event->volunteer_needs;
        if (is_string($roles)) {
            $roles = json_decode($roles, true);
        }
        if (!is_array($roles)) $roles = [];

        $roles[] = [
            'role_name'    => $data['role_name'],
            'spots'        => (int)$data['spots'],
            'start_time'   => $data['start_time'] ?? null,
            'end_time'     => $data['end_time'] ?? null,
            'requirements' => $data['requirements'] ?? null,
            'benefits'     => $data['benefits'] ?? null,
        ];

        $event->volunteer_needs = $roles;
        $event->save();

        return response()->json([
            'message' => 'Volunteer role added successfully.',
            'volunteer_needs' => $event->volunteer_needs,
        ], 201);
    }

    // DELETE /api/organizer/events/{event}/volunteer-roles/{index}
    public function destroy(Request $request, Event $event, int $index)
    {
        $this->requireOrganizerOwner($request, $event);

        $roles = $event->volunteer_needs;
        if (is_string($roles)) {
            $roles = json_decode($roles, true);
        }
        if (!is_array($roles) || !isset($roles[$index])) {
            return response()->json(['message' => 'Role not found.'], 404);
        }

        array_splice($roles, $index, 1);

        $event->volunteer_needs = $roles;
        $event->save();

        return response()->json([
            'message' => 'Volunteer role deleted successfully.',
            'volunteer_needs' => $event->volunteer_needs,
        ]);
    }
}
