<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\VolunteerRequest;
use App\Models\OrganizerRequest;
use Illuminate\Http\Request;

class UserAdminController extends Controller
{
    protected function requireAdmin(Request $request)
    {
        $user = $request->user();

        if (! $user || ! $user->role || $user->role->name !== 'admin') {
            abort(response()->json([
                'message' => 'Only admins can perform this action.',
            ], 403));
        }

        return $user;
    }

    /**
     * GET /api/admin/users
     * - stats (total, regular_users, organizers)
     * - list with search + role filter
     */
    public function index(Request $request)
    {
        $this->requireAdmin($request);

        $query = User::query()->with(['role:id,name']);

        // search (name/email/phone/location)
        if ($search = $request->input('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ILIKE', "%{$search}%")
                  ->orWhere('email', 'ILIKE', "%{$search}%")
                  ->orWhere('phone', 'ILIKE', "%{$search}%")
                  ->orWhere('location', 'ILIKE', "%{$search}%");
            });
        }

        // role filter: user / organizer / admin
        if ($role = $request->input('role')) {
            $query->whereHas('role', function ($q) use ($role) {
                $q->where('name', $role);
            });
        }

        $perPage = $request->integer('per_page', 10);

        $users = $query
            ->orderByDesc('created_at')
            ->paginate($perPage);

        // stats
        $totalUsers = User::count();

        $regularUsers = User::whereHas('role', fn($q) => $q->where('name', 'user'))->count();
        $organizers   = User::whereHas('role', fn($q) => $q->where('name', 'organizer'))->count();

        return response()->json([
            'stats' => [
                'total_users'   => $totalUsers,
                'regular_users' => $regularUsers,
                'organizers'    => $organizers,
            ],
            'users' => $users,
        ]);
    }

    /**
     * DELETE /api/admin/users/{id}
     * يمنع الحذف إذا في علاقات (events/tickets/volunteer_requests/organizer_requests)
     */
    public function destroy(Request $request, $id)
    {
        $admin = $this->requireAdmin($request);

        if ((int)$admin->id === (int)$id) {
            return response()->json([
                'message' => 'You cannot delete yourself.',
            ], 422);
        }

        $user = User::with('role')->findOrFail($id);

        // ✅ منع حذف admin (اختياري لكن أنصح فيه)
        if ($user->role && $user->role->name === 'admin') {
            return response()->json([
                'message' => 'Cannot delete an admin user.',
            ], 422);
        }

        $hasEvents = Event::where('organizer_id', $user->id)->exists();
        $hasTickets = Ticket::where('user_id', $user->id)->exists();
        $hasVolunteerReq = VolunteerRequest::where('user_id', $user->id)->exists();
        $hasOrganizerReq = OrganizerRequest::where('user_id', $user->id)->exists();

        if ($hasEvents || $hasTickets || $hasVolunteerReq || $hasOrganizerReq) {
            return response()->json([
                'message' => 'Cannot delete user with related data (events/tickets/volunteer requests/organizer requests).',
                'details' => [
                    'has_events'            => $hasEvents,
                    'has_tickets'           => $hasTickets,
                    'has_volunteer_requests'=> $hasVolunteerReq,
                    'has_organizer_requests'=> $hasOrganizerReq,
                ],
            ], 422);
        }

        // إذا عندك صور مخزنة للمستخدم وتريد حذفها، اعملها هون (حسب تخزينك)

        $user->delete();

        return response()->json([
            'message' => 'User deleted successfully.',
        ]);
    }
}
