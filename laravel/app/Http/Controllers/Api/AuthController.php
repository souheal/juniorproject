<?php
  
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Role;
use App\Models\Category;
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
     *   "name": "string",
     *   "email": "string",
     *   "phone": "string",
     *   "location": "string",
     *   "birth_date": "YYYY-MM-DD",
     *   "password": "string",
     *   "password_confirmation": "string",
     *   "picture": "BASE64_STRING or null",
     *   "categories": ["Information Technology", "Student", ...]
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
            'picture'               => ['nullable', 'string'],      // base64 or null
            'categories'            => ['required', 'array', 'min:1'],
            'categories.*'          => ['string', 'exists:categories,name'], // each must be a valid category name
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
                // Here we assume Flutter sends raw base64 string (no "data:image/...;base64," prefix).
                // If they send full data URI later, you can strip the prefix before decoding.
                $binary = base64_decode($validated['picture']);

                if ($binary !== false) {
                    $filename = 'profile_' . Str::uuid()->toString() . '.jpg';
                    $path = 'profiles/' . $filename;

                    Storage::disk('public')->put($path, $binary);

                    $imagePath = $path;
                }
            } catch (\Throwable $e) {
                // If decoding fails, ignore the picture for now.
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

        // 5. Attach categories (many-to-many)
        //    We receive category NAMES, need to convert them to IDs.
        $categoryNames = $validated['categories']; // array of strings
        $categoryIds = Category::whereIn('name', $categoryNames)->pluck('id')->all();

        $user->categories()->sync($categoryIds);

        // 6. Build picture URL (if you ran `php artisan storage:link`)
        $pictureUrl = $imagePath ? asset('storage/' . $imagePath) : null;

        // 7. Return JSON response (including categories as names)
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
                'categories'  => $user->categories()->pluck('name'),
            ],
        ], 201);
    }
}
