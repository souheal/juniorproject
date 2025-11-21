<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;

Route::prefix('auth')->controller(AuthController::class)->group(function () {
    Route::post('/register', 'register');
    Route::post('/login', 'login');
    Route::get('/verify-email', 'verifyEmail'); // 👈 جديد
    Route::post('/logout', 'logout')->middleware('auth:sanctum'); // لو عندك logout
});

