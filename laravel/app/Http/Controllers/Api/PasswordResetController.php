<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\PasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Mail;

class PasswordResetController extends Controller
{
    /**
     * Step 1: Request reset (send OTP via EMAIL)
     *
     * POST /api/password/forgot
     * {
     *   "email": "user@example.com"
     * }
     */
    public function requestReset(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $user = User::where('email', $data['email'])->first();

        // For security, don't reveal whether the email exists
        if (!$user) {
            return response()->json([
                'message' => 'If this email exists, a reset code has been sent.',
            ]);
        }

        // generate 6-digit code
        $code = random_int(100000, 999999);

        $expiresAt = Carbon::now()->addMinutes(10);

        // store reset record
        PasswordReset::create([
            'user_id'    => $user->id,
            'email'      => $user->email,
            'code'       => (string) $code,
            'expires_at' => $expiresAt,
        ]);

        // Send email - you can replace this with your Twilio email logic if you have one
        try {
            Mail::raw(
                "Your password reset code is: {$code}. It expires in 10 minutes.",
                function ($message) use ($user) {
                    $message->to($user->email)
                            ->subject('Your password reset code');
                }
            );
        } catch (\Throwable $e) {
            return response()->json([
                'message' => 'Failed to send reset code. Please try again later.',
            ], 500);
        }

        return response()->json([
            'message' => 'If this email exists, a reset code has been sent.',
        ]);
    }

    /**
     * Step 2: Verify code & reset password
     *
     * POST /api/password/reset
     * {
     *   "email": "user@example.com",
     *   "code": "123456",
     *   "password": "newpass",
     *   "password_confirmation": "newpass"
     * }
     */
    public function reset(Request $request)
    {
        $data = $request->validate([
            'email'                 => ['required', 'email'],
            'code'                  => ['required', 'string'],
            'password'              => ['required', 'string', 'min:6', 'confirmed'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (!$user) {
            return response()->json([
                'message' => 'Invalid code or email.',
            ], 400);
        }

        $reset = PasswordReset::where('user_id', $user->id)
            ->where('email', $data['email'])
            ->where('code', $data['code'])
            ->whereNull('used_at')
            ->orderByDesc('id')
            ->first();

        if (!$reset) {
            return response()->json([
                'message' => 'Invalid or expired reset code.',
            ], 400);
        }

        if ($reset->expires_at->isPast()) {
            return response()->json([
                'message' => 'Reset code has expired.',
            ], 400);
        }

        // Thanks to 'password' => 'hashed', this will auto-hash
        $user->password = $data['password'];
        $user->save();

        // Mark this code as used
        $reset->used_at = Carbon::now();
        $reset->save();

        return response()->json([
            'message' => 'Password has been reset successfully.',
        ]);
    }
}
