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
        // إذا event مو محمّل، حمّله
        if (! $ticket->relationLoaded('event')) {
            $ticket->load('event');
        }

        $this->ticket = $ticket;
        $this->event  = $ticket->event;
    }

    public function build()
    {
        $eventName = $this->event?->name ?? 'your event';

        return $this
            ->subject('Your ticket for ' . $eventName)
            ->view('emails.tickets.paid')
            ->with([
                'ticket' => $this->ticket,
                'event'  => $this->event,
            ]);
    }
}
