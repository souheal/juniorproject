<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class VerifyEmailMail extends Mailable
{
    use Queueable, SerializesModels;

    public User $user;
    public string $otpCode;

    /**
     * Create a new message instance.
     */
    public function __construct(User $user, string $otpCode)
    {
        $this->user = $user;
        $this->otpCode = $otpCode;
    }

    /**
     * Build the message.
     */
    public function build()
    {
        return $this->subject('Your Verification Code - Eventy')
                    ->view('emails.verify-email-otp')
                    ->with([
                        'user' => $this->user,
                        'otpCode' => $this->otpCode,
                    ]);
    }
}
