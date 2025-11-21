<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PasswordResetController;

Route::prefix('auth')->controller(AuthController::class)->group(function () {
    Route::post('/register', 'register');
    Route::post('/login', 'login');
    Route::post('/signup', [AuthController::class, 'register']);
    Route::get('/verify-email', 'verifyEmail'); // 👈 جديد
    Route::post('/logout', 'logout')->middleware('auth:sanctum'); // لو عندك logout
    Route::post('/password/forgot', [PasswordResetController::class, 'requestReset']);
    Route::post('/password/reset', [PasswordResetController::class, 'reset']);

});

