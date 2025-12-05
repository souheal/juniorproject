<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ticket confirmation</title>
</head>
<body>
    <h2>Hello {{ $ticket->user->name }},</h2>

    <p>
        Your payment for the event
        <strong>{{ $event->name }}</strong>
        has been received successfully.
    </p>

    <p>
        <strong>Event details:</strong><br>
        City: {{ $event->city }}<br>
        Location: {{ $event->location }}<br>
        Date &amp; time:
        {{ $event->start_time }} – {{ $event->end_time }}<br>
        Price: {{ $event->price }} {{ config('services.stripe.currency', 'usd') }}
    </p>

    <p>
        Please show this QR code at the entrance.
        It can be scanned <strong>only once</strong>.
    </p>

    <p><strong>QR Code:</strong></p>

    <p>
        <img
            src="https://api.qrserver.com/v1/create-qr-code/?size=250x250&data={{ urlencode($ticket->qr_code) }}"
            alt="QR Code"
            width="250"
            height="250"
        >
    </p>

    <p style="font-size: 12px; color: #555;">
        This code is unique for your ticket and will be marked as used
        after the first scan.
    </p>

    <p>Thank you for using JuniorProject 🚀</p>
</body>
</html>
