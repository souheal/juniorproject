<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Models\OrganizerRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class OrganizerRequestController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user();

        // 🧠 منطق بسيط: فقط user العادي يقدّم طلب
        if ($user->role && $user->role->name !== 'user') {
            return response()->json([
                'message' => 'Only normal users can submit organizer requests',
            ], 403);
        }

        // ✅ Validate
        $validated = $request->validate([
            'organization_name' => ['required', 'string', 'max:255'],
            'description'       => ['nullable', 'string'],
            // إذا بدك تجبره يرسل ملف حقيقي، خليه required|file
            'documents'         => ['nullable', 'file', 'mimes:pdf,jpg,jpeg,png', 'max:4096'],
        ]);

        // 🗂️ رفع الملف لو موجود
        $documentsPath = null;
        if ($request->hasFile('documents')) {
            $documentsPath = $request->file('documents')->store('organizer_docs', 'public');
        }

        $req = OrganizerRequest::create([
            'user_id'           => $user->id,
            'organization_name' => $validated['organization_name'],
            'description'       => $validated['description'] ?? null,
            'documents'         => $documentsPath ?? 'N/A', // لو عمود documents مو nullable
            'status'            => 'pending',
            'admin_comment'     => null,
        ]);

        return response()->json([
            'message' => 'Organizer request sent successfully',
            'request' => $req->load('user:id,name,email'),
        ], 201);
    }
}
