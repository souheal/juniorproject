<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class StripeWebhookController extends Controller
{
    /**
     * هذا الويبهوك تم إلغاء استخدامه.
     * نستخدم فقط: PaymentController@webhook
     */
    public function handle(Request $request)
    {
        Log::warning('Deprecated StripeWebhookController endpoint called. Ignored.');

        return response()->json([
            'message' => 'This webhook endpoint is deprecated. Use /api/payments/stripe/webhook',
        ], 410);
    }
}
