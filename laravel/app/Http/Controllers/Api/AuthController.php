<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Role;
use App\Models\Category;
use App\Models\VolunteerRequest;
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

class AuthController extends Controller
{
    /**
     * Register user + send 6-digit verification code
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
                'message' => 'Role "user" not found',
            ], 500);
        }

        // ---------- profile picture ----------
        $picturePath = null;

        if (!empty($validated['picture']) && $validated['picture'] !== 'null') {
            try {
                $base64 = $validated['picture'];
                $extension = 'png';

                if (str_starts_with($base64, 'data:image')) {
                    [$meta, $base64] = explode(',', $base64, 2);
                    if (str_contains($meta, 'jpeg') || str_contains($meta, 'jpg')) {
                        $extension = 'jpg';
                    } elseif (str_contains($meta, 'webp')) {
                        $extension = 'webp';
                    }
                }

                $binary = base64_decode($base64, true);
                if ($binary === false) {
                    throw new \RuntimeException('Invalid base64');
                }

                $fileName = 'profile_pictures/' . Str::uuid() . '.' . $extension;
                Storage::disk('public')->put($fileName, $binary);
                $picturePath = $fileName;

            } catch (\Throwable $e) {
                Log::error('Profile picture failed', [
                    'email' => $validated['email'],
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // ---------- create user ----------
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

            if (!empty($validated['categories'])) {
                $categoryIds = Category::whereIn('name', $validated['categories'])->pluck('id');
                $user->categories()->sync($categoryIds);
            }
        });

        // ---------- OTP ----------
        $code = random_int(100000, 999999);
        $user->email_verification_token = (string) $code;
        $user->save();

        try {
            Mail::to($user->email)->send(new VerifyEmailMail($user, $code));
        } catch (\Throwable $e) {
            Log::error('OTP mail failed', [
                'user_id' => $user->id,
                'error'   => $e->getMessage(),
            ]);
        }

        return response()->json([
            'message' => 'Verification code sent to your email',
        ], 201);
    }

    /**
     * Verify email using OTP code
     */
    public function verifyEmailCode(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'code'  => ['required', 'digits:6'],
        ]);

        $user = User::where('email', $data['email'])
            ->where('email_verification_token', $data['code'])
            ->first();

        if (! $user) {
            return response()->json([
                'message' => 'Invalid verification code',
            ], 400);
        }

        $user->email_verified_at = now();
        $user->email_verification_token = null;
        $user->save();

        return response()->json([
            'message' => 'Email verified successfully',
        ]);
    }

    /**
     * Login
     */
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

        $currentIp   = $request->ip();
        $isNewDevice = $user->last_login_ip !== $currentIp;

        $user->last_login_ip = $currentIp;
        $user->save();

        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        if ($isNewDevice) {
            try {
                Mail::to($user->email)->send(new NewLoginMail($user, $currentIp));
            } catch (\Throwable $e) {
                Log::error('New login mail failed', [
                    'user_id' => $user->id,
                    'error'   => $e->getMessage(),
                ]);
            }
        }

        return response()->json([
            'message' => 'Login successful',
            'user'    => $user,
            'token'   => $token,
        ]);
    }

    /**
     * Logout
     */
    public function logout(Request $request)
    {
        $user = $request->user();
        $user?->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'Logged out successfully',
        ]);
    }
}
