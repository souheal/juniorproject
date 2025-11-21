<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Role;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * Register (signup) a new user.
     * Expects JSON with optional base64-encoded "picture".
     */
    public function register(Request $request)
    {
        // 1) Validate request
        $validated = $request->validate([
            'name'                  => ['required', 'string', 'max:255'],
            'email'                 => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone'                 => ['required', 'string', 'max:50'],
            'location'              => ['required', 'string', 'max:255'],
            'birth_date'            => ['required', 'date'],
            'password'              => ['required', 'string', 'min:6', 'confirmed'],
            // picture is base64 string or null
            'picture'               => ['nullable', 'string'],
            // categories as array of category names that already exist in `categories` table
            'categories'            => ['nullable', 'array'],
            'categories.*'          => ['string', Rule::exists('categories', 'name')],
        ]);

        // 2) Fetch the "user" role (assuming it's seeded)
        $userRole = Role::where('name', 'user')->first();

        if (! $userRole) {
            return response()->json([
                'message' => 'Role "user" not found. Make sure roles are seeded.',
            ], 500);
        }

        // 3) Handle base64 picture (if present)
        $picturePath = null;

        if (isset($validated['picture']) && $validated['picture'] !== null && $validated['picture'] !== 'null') {
            $base64 = $validated['picture'];

            try {
                $extension = 'png';

                // If it's a data URL like "data:image/png;base64,AAA..."
                if (str_starts_with($base64, 'data:image')) {
                    $parts = explode(',', $base64, 2);
                    if (count($parts) === 2) {
                        $meta = $parts[0];      // e.g. "data:image/png;base64"
                        $base64 = $parts[1];    // real base64 data

                        if (str_contains($meta, 'image/jpeg')) {
                            $extension = 'jpg';
                        } elseif (str_contains($meta, 'image/jpg')) {
                            $extension = 'jpg';
                        } elseif (str_contains($meta, 'image/webp')) {
                            $extension = 'webp';
                        }
                    }
                }

                $binary = base64_decode($base64, true);

                if ($binary === false) {
                    throw new \RuntimeException('Invalid base64 image data');
                }

                $fileName = Str::uuid()->toString() . '.' . $extension;
                $path = 'profile_pictures/' . $fileName;

                Storage::disk('public')->put($path, $binary);

                $picturePath = $path;
            } catch (\Throwable $e) {
                // If decoding fails, just log it and continue without a picture
                Log::error('Failed to decode/store profile picture', [
                    'email' => $validated['email'] ?? null,
                    'error' => $e->getMessage(),
                ]);
                $picturePath = null;
            }
        }

        // 4) Create user + attach categories inside a transaction
        $user = null;

        DB::transaction(function () use (&$user, $validated, $userRole, $picturePath) {
            $user = User::create([
                'role_id'    => $userRole->id,
                'name'       => $validated['name'],
                'email'      => $validated['email'],
                'phone'      => $validated['phone'],
                'location'   => $validated['location'],
                'birth_date' => $validated['birth_date'],
                'password'   => Hash::make($validated['password']),
                'picture'    => $picturePath,
            ]);

            if (! empty($validated['categories'])) {
                $categoryIds = Category::whereIn('name', $validated['categories'])
                    ->pluck('id')
                    ->all();

                if (! empty($categoryIds)) {
                    $user->categories()->sync($categoryIds);
                }
            }
        });

        // 5) Try to send verification email (but DO NOT break if it fails)
        try {
            // Put your actual mailable here if you have one, for example:
            // Mail::to($user->email)->send(new \App\Mail\VerifyEmailMail($user));

        } catch (\Throwable $e) {
            Log::error('Failed to send verification email', [
                'user_id' => $user->id,
                'email'   => $user->email,
                'error'   => $e->getMessage(),
            ]);
            // Do NOT rethrow; let registration succeed
        }

        return response()->json([
            'message' => 'User registered successfully',
            'user'    => $user,
        ], 201);
    }
    

public function login(Request $request)
{
    $data = $request->validate([
        'email'    => ['required', 'email'],
        'password' => ['required', 'string', 'min:6'],
    ]);

    $user = User::where('email', $data['email'])->first();

    if (! $user || ! Hash::check($data['password'], $user->password)) {
        return response()->json([
            'message' => 'Invalid email or password',
        ], 401);
    }

    if ($user->email_verified_at === null) {
        return response()->json([
            'message' => 'Email is not verified',
        ], 403);
    }

    // 👇👇 من هون منبدأ شغل الـ IP
    $currentIp = $request->ip();              // IP الحالي
    $previousIp = $user->last_login_ip;       // آخر IP مخزّن (ممكن يكون null أول مرة)

    $isNewIp = $previousIp !== $currentIp;

    if ($isNewIp) {
        // ابعت إيميل للمستخدم إن في تسجيل دخول من IP جديد
        Mail::to($user->email)->send(new NewLoginMail($user, $currentIp, $previousIp));
    }

    // حدّث آخر IP سواء جديد أو نفسو
    $user->last_login_ip = $currentIp;
    $user->save();
    // 👆👆 هون خلصنا منطق الـ IP

    // باقي منطق التوكن زي ما كان
    $user->tokens()->delete();
    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'message' => 'Logged in successfully',
        'user'    => $user,
        'token'   => $token,
    ]);
}


public function verifyEmail(Request $request)
{
    $request->validate([
        'token' => ['required', 'string'],
    ]);

    $user = User::where('email_verification_token', $request->token)->first();

    if (! $user) {
        return response()->json([
            'message' => 'Invalid or expired verification token',
        ], 400);
    }

    // لو هو أصلاً مفعّل
    if ($user->email_verified_at !== null) {
        return response()->json([
            'message' => 'Email is already verified',
        ], 200);
    }

    $user->email_verified_at = now();
    $user->email_verification_token = null;
    $user->save();

    return response()->json([
        'message' => 'Email verified successfully',
    ], 200);
}



    /**
     * Logout (for Sanctum)
     */
    public function logout(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        if ($user) {
            $user->currentAccessToken()?->delete();
        }

        return response()->json([
            'message' => 'Logged out successfully',
        ]);
    }

    /**
     * Example verify-email endpoint (placeholder).
     */
    public function verifyEmail(Request $request)
    {
        $email = $request->query('email');

        if (! $email) {
            return response()->json([
                'message' => 'Email is required',
            ], 400);
        }

        $user = User::where('email', $email)->first();

        if (! $user) {
            return response()->json([
                'message' => 'User not found',
            ], 404);
        }

        if ($user->email_verified_at) {
            return response()->json([
                'message' => 'Email already verified',
            ]);
        }

        // TODO: check your verification code here if you have one.

        $user->email_verified_at = now();
        $user->save();

        return response()->json([
            'message' => 'Email verified successfully',
        ]);
    }
}
