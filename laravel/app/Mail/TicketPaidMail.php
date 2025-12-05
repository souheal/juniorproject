<?php

namespace App\Mail;

use App\Models\Ticket;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class TicketPaidMail extends Mailable
{
    use Queueable, SerializesModels;

    public Ticket $ticket;
    public $event;

    public function __construct(Ticket $ticket)
    {
        $this->ticket = $ticket;
        $this->event  = $ticket->event;
    }

    public function build()
    {
        return $this
            ->subject('Your ticket for ' . $this->event->name)
            ->view('emails.tickets.paid')
            ->with([
                'ticket' => $this->ticket,
                'event'  => $this->event,
            ]);
    }
}
