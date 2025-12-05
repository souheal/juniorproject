<?php

use Illuminate\Support\Facades\Route;

Route::get('/payment/success', function () {
    return 'Payment success (test page). You can customize this later.';
});

Route::get('/payment/cancel', function () {
    return 'Payment was cancelled.';
});

