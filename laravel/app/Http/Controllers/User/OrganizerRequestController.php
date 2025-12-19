<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Models\OrganizerRequest;
use Illuminate\Http\Request;

class OrganizerRequestController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user();

        // فقط user العادي يقدّم طلب
        if ($user->role && $user->role->name !== 'user') {
            return response()->json([
                'message' => 'Only normal users can submit organizer requests',
            ], 403);
        }

        $validated = $request->validate([
            'organization_name' => ['required', 'string', 'max:255'],
            'description'       => ['nullable', 'string'],
            'documents'         => ['nullable', 'file', 'mimes:pdf,jpg,jpeg,png', 'max:4096'],
        ]);

        $documentsPath = null;
        if ($request->hasFile('documents')) {
            $documentsPath = $request->file('documents')->store('organizer_docs', 'public');
        }

        $req = OrganizerRequest::create([
            'user_id'           => $user->id,
            'organization_name' => $validated['organization_name'],
            'description'       => $validated['description'] ?? null,
            'documents'         => $documentsPath ?? 'N/A',
            'status'            => 'pending',
            'admin_comment'     => null,
        ]);

        return response()->json([
            'message' => 'Organizer request sent successfully',
            'request' => $req->load('user:id,name,email'),
        ], 201);
    }

    /**
     * GET /api/organizer-requests/me
     */
    public function myRequests(Request $request)
    {
        $user = $request->user();

        $requests = OrganizerRequest::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get();

        return response()->json($requests);
    }
}
