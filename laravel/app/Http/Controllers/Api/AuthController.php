<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * Handle user registration (sign up).
     *
     * Expected JSON body:
     * {
     *   "name": "...",
     *   "email": "...",
     *   "phone": "...",
     *   "location": "...",
     *   "birth_date": "YYYY-MM-DD",
     *   "password": "...",
     *   "password_confirmation": "...",
     *   "picture": "BASE64_STRING" (optional)
     * }
     */
    public function register(Request $request)
    {
        // 1. Validate incoming data
        $validated = $request->validate([
            'name'                  => ['required', 'string', 'max:255'],
            'email'                 => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone'                 => ['required', 'string', 'max:30'],
            'location'              => ['required', 'string', 'max:255'],
            'birth_date'            => ['required', 'date'],      
            'password'              => ['required', 'string', 'min:6', 'confirmed'],
            'picture'               => ['nullable', 'string'],    // base64 string (later from Flutter)
        ]);

        // 2. Decide the role; user NEVER sends role_id
        $roleId = Role::where('name', 'user')->value('id');

        if (!$roleId) {
            return response()->json([
                'message' => 'Role "user" not found. Make sure roles are seeded.',
            ], 500);
        }

        // 3. If picture provided (base64), decode and store it
        $imagePath = null;

        if (!empty($validated['picture'])) {
            try {
                // if Flutter sends raw base64 (no "data:image/...;base64," prefix)
                $binary = base64_decode($validated['picture']);

                if ($binary !== false) {
                    // Generate unique filename
                    $filename = 'profile_' . Str::uuid()->toString() . '.jpg';
                    $path = 'profiles/' . $filename;

                    // Store in storage/app/public/profiles
                    Storage::disk('public')->put($path, $binary);

                    $imagePath = $path;
                }
            } catch (\Throwable $e) {
                // If decoding fails, just ignore the picture for now.
                $imagePath = null;
            }
        }

        // 4. Create the user
        //    Password will be automatically hashed because of 'password' => 'hashed' in User::casts()
        $user = User::create([
            'role_id'    => $roleId,
            'name'       => $validated['name'],
            'email'      => $validated['email'],
            'phone'      => $validated['phone'],
            'location'   => $validated['location'],
            'birth_date' => $validated['birth_date'],
            'password'   => $validated['password'],
            'picture'    => $imagePath,
        ]);

        // 5. Build picture URL (if you ran `php artisan storage:link`)
        $pictureUrl = $imagePath ? asset('storage/' . $imagePath) : null;

        // 6. Return JSON response
        return response()->json([
            'message' => 'User registered successfully',
            'user'    => [
                'id'          => $user->id,
                'name'        => $user->name,
                'email'       => $user->email,
                'phone'       => $user->phone,
                'location'    => $user->location,
                'birth_date'  => $user->birth_date,
                'role_id'     => $user->role_id,
                'picture'     => $user->picture,
                'picture_url' => $pictureUrl,
            ],
        ], 201);
    }
}
