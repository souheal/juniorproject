<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class NewLoginMail extends Mailable
{
    use Queueable, SerializesModels;

    public User $user;
    public string $currentIp;
    public ?string $previousIp;

    public function __construct(User $user, string $currentIp, ?string $previousIp = null)
    {
        $this->user = $user;
        $this->currentIp = $currentIp;
        $this->previousIp = $previousIp;
    }

    public function build()
    {
        return $this->subject('New login to your account')
                    ->markdown('emails.new-login');
    }
}
