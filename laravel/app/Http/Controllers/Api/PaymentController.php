<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\TicketPaidMail;
use App\Models\Event;
use App\Models\Ticket;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
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

        // 1) الحدث بدأ أو خلص؟
        if ($event->start_time < now()) {
            return response()->json([
                'message' => 'Event already started or finished.',
            ], 422);
        }

        // 2) عدد التذاكر المدفوعة
        $paidTicketsCount = Ticket::where('event_id', $event->id)
            ->where('payment_status', 'paid')
            ->count();

        if ($paidTicketsCount >= $event->capacity) {
            return response()->json([
                'message' => 'Event is sold out.',
            ], 422);
        }

        // 3) منع تكرار شراء تذكرة لنفس الحدث (اختياري)
        $alreadyHasTicket = Ticket::where('event_id', $event->id)
            ->where('user_id', $user->id)
            ->where('payment_status', 'paid')
            ->exists();

        if ($alreadyHasTicket) {
            return response()->json([
                'message' => 'You already have a paid ticket for this event.',
            ], 422);
        }

        // 4) إنشاء تذكرة بحالة pending و QR فريد (UUID)
        $ticket = Ticket::create([
            'event_id'       => $event->id,
            'user_id'        => $user->id,
            'qr_code'        => Str::uuid()->toString(), // فريد لكل تذكرة
            'is_scanned'     => false,
            'scanned_at'     => null,
            'payment_status' => 'pending',
        ]);

        // 5) إنشاء Payment بحالة pending
        $payment = Payment::create([
            'ticket_id' => $ticket->id,
            'amount'    => $event->price,     // numeric(9,3)
            'method'    => 'stripe',
            'status'    => 'pending',
        ]);

        // 6) Stripe Checkout Session
        Stripe::setApiKey(config('services.stripe.secret'));

        $session = StripeSession::create([
            'mode' => 'payment',
            'payment_method_types' => ['card'],
            'line_items' => [[
                'quantity' => 1,
                'price_data' => [
                    'currency'    => config('services.stripe.currency', 'usd'),
                    'unit_amount' => (int) round($event->price * 100), // إلى سنت
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
    }

    /**
     * Webhook من Stripe
     * POST /api/payments/stripe/webhook
     */
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

            if ($ticketId && $paymentId) {
                $ticket = Ticket::with(['event', 'user'])->find($ticketId);
                $payment = Payment::find($paymentId);

                if ($ticket) {
                    $ticket->payment_status = 'paid';
                    $ticket->save();
                }

                if ($payment) {
                    $payment->status = 'completed';
                    $payment->save();
                }

                // إرسال الإيميل بدون توليد صورة محلياً (الصورة من API خارجي)
                if ($ticket && $ticket->user && $ticket->event) {
                    try {
                        Mail::to($ticket->user->email)
                            ->send(new TicketPaidMail($ticket));
                    } catch (\Throwable $e) {
                        \Log::error('Failed to send TicketPaidMail', [
                            'ticket_id' => $ticket->id,
                            'error'     => $e->getMessage(),
                        ]);
                    }
                }
            }
        }

        return response()->json(['received' => true]);
    }
}
