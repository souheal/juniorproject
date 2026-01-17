<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\TicketPaidMail;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Stripe\Stripe;
use Stripe\Checkout\Session as StripeSession;
use Stripe\Webhook as StripeWebhook;

class PaymentController extends Controller
{
    /**
     * إنشاء Checkout Session لحدث معيّن
     * POST /api/events/{event}/checkout
     */
    public function checkout(Request $request, Event $event)
    {
        $user = $request->user();

        // الحدث بدأ أو خلص
        if ($event->start_time < now()) {
            return response()->json([
                'message' => 'Event already started or finished.',
            ], 422);
        }

        // عدد التذاكر المدفوعة
        $paidTicketsCount = Ticket::where('event_id', $event->id)
            ->where('payment_status', 'paid')
            ->count();

        // حجز مؤقت
        $pendingHoldCount = Ticket::where('event_id', $event->id)
            ->where('payment_status', 'pending')
            ->where('created_at', '>=', now()->subMinutes(15))
            ->count();

        if (($paidTicketsCount + $pendingHoldCount) >= $event->capacity) {
            return response()->json([
                'message' => 'Event is sold out.',
            ], 422);
        }

        // منع تكرار شراء تذكرة مدفوعة لنفس الحدث
        $alreadyHasTicket = Ticket::where('event_id', $event->id)
            ->where('user_id', $user->id)
            ->where('payment_status', 'paid')
            ->exists();

        if ($alreadyHasTicket) {
            return response()->json([
                'message' => 'You already have a paid ticket for this event.',
            ], 422);
        }

        // إنشاء Ticket pending
        $ticket = Ticket::create([
            'event_id'       => $event->id,
            'user_id'        => $user->id,
            'qr_code'        => Str::uuid()->toString(),
            'is_scanned'     => false,
            'scanned_at'     => null,
            'payment_status' => 'pending',
        ]);

        // إنشاء Payment pending
        $payment = Payment::create([
            'ticket_id' => $ticket->id,
            'amount'    => $event->price,
            'method'    => 'stripe',
            'status'    => 'pending',
        ]);

        try {
            Stripe::setApiKey(config('services.stripe.secret'));

            $session = StripeSession::create([
                'mode' => 'payment',
                'payment_method_types' => ['card'],
                'line_items' => [[
                    'quantity' => 1,
                    'price_data' => [
                        'currency'    => config('services.stripe.currency', 'usd'),
                        'unit_amount' => (int) round($event->price * 100),
                        'product_data' => [
                            'name'        => $event->name,
                            'description' => $event->city . ' - ' . $event->location,
                        ],
                    ],
                ]],
                'metadata' => [
                    'ticket_id'  => $ticket->id,
                    'payment_id' => $payment->id,
                    'user_id'    => $user->id,
                    'event_id'   => $event->id,
                ],
                'success_url' => config('services.stripe.success_url') . '?session_id={CHECKOUT_SESSION_ID}',
                'cancel_url'  => config('services.stripe.cancel_url'),
            ]);

            return response()->json([
                'checkout_url' => $session->url,
                'session_id'   => $session->id,
            ]);
        } catch (\Throwable $e) {
            Log::error('Stripe checkout session create failed', [
                'event_id' => $event->id,
                'user_id'  => $user->id,
                'ticket_id'=> $ticket->id,
                'payment_id'=> $payment->id,
                'error'    => $e->getMessage(),
            ]);

    
            $payment->status = 'cancelled';
            $payment->save();

            $ticket->payment_status = 'cancelled';
            $ticket->save();

            return response()->json([
                'message' => 'Failed to start payment. Please try again.',
            ], 500);
        }
    }


    public function webhook(Request $request)
    {
        $payload   = $request->getContent();
        $sigHeader = $request->header('Stripe-Signature');
        $secret    = config('services.stripe.webhook_secret');

        try {
            $stripeEvent = StripeWebhook::constructEvent(
                $payload,
                $sigHeader,
                $secret
            );
        } catch (\Throwable $e) {
            return response()->json(['message' => 'Invalid signature'], 400);
        }

        if ($stripeEvent->type === 'checkout.session.completed') {
            /** @var \Stripe\Checkout\Session $session */
            $session = $stripeEvent->data->object;

            $ticketId  = $session->metadata->ticket_id ?? null;
            $paymentId = $session->metadata->payment_id ?? null;

            if (!$ticketId || !$paymentId) {
                Log::warning('Stripe webhook missing ticket_id/payment_id in metadata');
                return response()->json(['received' => true]);
            }

            $ticket  = Ticket::with(['event', 'user'])->find($ticketId);
            $payment = Payment::find($paymentId);

            if (!$ticket || !$payment) {
                Log::error('Stripe webhook ticket/payment not found', [
                    'ticket_id'  => $ticketId,
                    'payment_id' => $paymentId,
                ]);
                return response()->json(['received' => true]);
            }

            //  حماية من التكرار
            if ($ticket->payment_status === 'paid' || $payment->status === 'completed') {
                return response()->json(['received' => true]);
            }

            //  علّمهم مدفوع/مكتمل
            $ticket->payment_status = 'paid';
            $ticket->save();

            $payment->status = 'completed';
            $payment->save();

            //  ايميل تأكيد 
            if ($ticket->user && $ticket->event) {
                try {
                    Mail::to($ticket->user->email)->send(new TicketPaidMail($ticket));
                } catch (\Throwable $e) {
                    Log::error('Failed to send TicketPaidMail', [
                        'ticket_id' => $ticket->id,
                        'error'     => $e->getMessage(),
                    ]);
                }
            }
        }

        return response()->json(['received' => true]);
    }
}
