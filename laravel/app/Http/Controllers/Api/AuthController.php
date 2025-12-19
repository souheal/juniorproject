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
use App\Mail\VerifyEmailMail;
use App\Mail\NewLoginMail;
use App\Models\VolunteerRequest;

class AuthController extends Controller
{
    /**
     * Register (signup) a new user.
     * Expects JSON with optional base64-encoded "picture".
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name'                  => ['required', 'string', 'max:255'],
            'email'                 => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone'                 => ['required', 'string', 'max:50'],
            'location'              => ['required', 'string', 'max:255'],
            'birth_date'            => ['required', 'date'],
            'password'              => ['required', 'string', 'min:6', 'confirmed'],
            'picture'               => ['nullable', 'string'],
            'categories'            => ['nullable', 'array'],
            'categories.*'          => ['string', Rule::exists('categories', 'name')],
        ]);

        $userRole = Role::where('name', 'user')->first();

        if (! $userRole) {
            return response()->json([
                'message' => 'Role "user" not found. Make sure roles are seeded.',
            ], 500);
        }

        // Base64 picture
        $picturePath = null;

        if (isset($validated['picture']) && $validated['picture'] !== null && $validated['picture'] !== 'null') {
            $base64 = $validated['picture'];

            try {
                $extension = 'png';

                if (str_starts_with($base64, 'data:image')) {
                    $parts = explode(',', $base64, 2);
                    if (count($parts) === 2) {
                        $meta = $parts[0];
                        $base64 = $parts[1];

                        if (str_contains($meta, 'image/jpeg') || str_contains($meta, 'image/jpg')) {
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
                $path     = 'profile_pictures/' . $fileName;

                Storage::disk('public')->put($path, $binary);

                $picturePath = $path;
            } catch (\Throwable $e) {
                Log::error('Failed to decode/store profile picture', [
                    'email' => $validated['email'] ?? null,
                    'error' => $e->getMessage(),
                ]);
                $picturePath = null;
            }
        }

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

        // Email verification token
        $token = Str::random(64);
        $user->email_verification_token = $token;
        $user->save();

        $verificationUrl = url('/api/auth/verify-email?token=' . $token);

        try {
            Mail::to($user->email)->send(new VerifyEmailMail($user, $token));
        } catch (\Throwable $e) {
            Log::error('Failed to send verification email', [
                'user_id' => $user->id,
                'email'   => $user->email,
                'error'   => $e->getMessage(),
            ]);
        }

        return response()->json([
            'message'          => 'User registered successfully',
            'verification_url' => $verificationUrl,
            'user'             => $user,
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

<<<<<<< HEAD
        if ($user->email_verified_at === null) {
            return response()->json([
                'message' => 'Email is not verified',
            ], 403);
        }
=======
        // لازم يكون الإيميل مفعَّل
        // if ($user->email_verified_at === null) {
        //     return response()->json([
        //         'message' => 'Email is not verified',
        //     ], 403);
        // }
>>>>>>> cb03bf2af490fc099764dac3c1f7b1855affdf2b

        $currentIp   = $request->ip();
        $isNewDevice = $user->last_login_ip !== $currentIp;

        $user->last_login_ip = $currentIp;
        $user->save();

        // حذف التوكنات القديمة (اختياري)
        $user->tokens()->delete();

        $token = $user->createToken('auth_token')->plainTextToken;

        // ✅ لا تخلي الإيميل يوقع تسجيل الدخول
        if ($isNewDevice) {
            try {
                Mail::to($user->email)->send(new NewLoginMail($user, $currentIp));
            } catch (\Throwable $e) {
<<<<<<< HEAD
                Log::error('Failed to send NewLoginMail', [
                    'user_id' => $user->id,
                    'email'   => $user->email,
                    'ip'      => $currentIp,
                    'error'   => $e->getMessage(),
                ]);
=======
                Log::error('Failed to send new login email', [
                    'user_id' => $user->id,
                    'email'   => $user->email,
                    'error'   => $e->getMessage(),
                ]);
                // Continue login even if email fails
>>>>>>> cb03bf2af490fc099764dac3c1f7b1855affdf2b
            }
        }

        return response()->json([
            'message' => 'Login successful',
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

        if ($user->email_verified_at !== null) {
            return response()->json([
                'message' => 'Email is already verified',
            ], 200);
        }

        $user->email_verified_at         = now();
        $user->email_verification_token  = null;
        $user->save();

        return response()->json([
            'message' => 'Email verified successfully',
        ], 200);
    }

    public function me(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = $request->user();

        $user->load([
            'role:id,name',
            'categories:id,name',
        ]);

        $unreadNotificationsCount = $user->notifications()
            ->where('read_status', false)
            ->count();

        $organizerData = null;

        if ($user->role && $user->role->name === 'organizer') {

            $user->load('organizerProfile');

            $eventsCount = $user->events()->count();

            // ✅ إصلاح status: accepted (مو approved)
            $volunteerRequestsCount = VolunteerRequest::whereHas('event', function ($q) use ($user) {
                $q->where('organizer_id', $user->id);
            })->where('status', 'accepted')->count();

            $organizerData = [
                'profile'                   => $user->organizerProfile,
                'events_count'              => $eventsCount,
                'volunteer_requests_count'  => $volunteerRequestsCount,
            ];
        }

        return response()->json([
            'user'                       => $user,
            'unread_notifications_count' => $unreadNotificationsCount,
            'organizer_data'             => $organizerData,
        ]);
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
}
