<?php

use Illuminate\Support\Facades\Route;
// الصفحة الرئيسية
Route::get('/', function () {
    return 'HOME OK';
    // return view('welcome');
});
// صفحات الدفع
Route::get('/payment/success', function () {
    return 'Payment success (test page). You can customize this later.';
});

Route::get('/payment/cancel', function () {
    return 'Payment was cancelled.';
});
