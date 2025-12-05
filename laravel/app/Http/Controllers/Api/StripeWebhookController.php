<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use App\Models\Payment;
use App\Models\Ticket;
use App\Models\Event;
use App\Models\User;
use Illuminate\Support\Str;

class StripeWebhookController extends Controller
{
    public function handle(Request $request)
    {
        $payload    = $request->getContent();
        $sigHeader  = $request->header('Stripe-Signature');
        $secret     = env('STRIPE_WEBHOOK_SECRET');

        try {
            $event = \Stripe\Webhook::constructEvent(
                $payload,
                $sigHeader,
                $secret
            );
        } catch (\Throwable $e) {
            Log::error('Stripe webhook signature error', [
                'message' => $e->getMessage(),
            ]);

            return response()->json(['error' => 'Invalid signature'], 400);
        }

        switch ($event->type) {
            case 'checkout.session.completed':
                $this->handleCheckoutCompleted($event->data->object);
                break;

            default:
                Log::info('Stripe webhook ignored type: ' . $event->type);
        }

        return response()->json(['status' => 'ok']);
    }

    protected function handleCheckoutCompleted($session)
    {
        // metadata حطينا فيها IDs وقت إنشاء الـ session
        $eventId = $session->metadata->event_id ?? null;
        $userId  = $session->metadata->user_id ?? null;

        if (!$eventId || !$userId) {
            Log::error('Missing metadata in checkout.session.completed');
            return;
        }

        $event = Event::find($eventId);
        $user  = User::find($userId);

        if (!$event || !$user) {
            Log::error('Event or User not found for payment', [
                'event_id' => $eventId,
                'user_id'  => $userId,
            ]);
            return;
        }

        // amount الإجمالي من Stripe يكون بالـ cents
        $amount = $session->amount_total / 100;

        // 1) سجل payment
        $payment = Payment::create([
            'ticket_id' => null,            // نربطه بعد إنشاء التذكرة
            'amount'    => $amount,
            'method'    => 'stripe',
            'status'    => 'completed',
        ]);

        // 2) أنشئ Ticket لو ما في واحد
        $ticket = Ticket::create([
            'event_id'       => $event->id,
            'user_id'        => $user->id,
            'qr_code'        => Str::uuid()->toString(),
            'is_scanned'     => false,
            'scanned_at'     => null,
            'payment_status' => 'paid',
        ]);

        // اربط الـ payment بالتذكرة
        $payment->ticket_id = $ticket->id;
        $payment->save();

        // 3) (اختياري) ابعت إيميل تأكيد
        // لو الـ Mail لسه مو مجهز، خليه بعدين أو بس اعمل Log
        Log::info('Ticket created & payment completed', [
            'ticket_id' => $ticket->id,
            'user_id'   => $user->id,
        ]);
    }
}
