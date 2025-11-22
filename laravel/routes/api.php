<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\User\OrganizerRequestController;
use App\Http\Controllers\Admin\OrganizerRequestAdminController;
use App\Http\Controllers\Api\NotificationController;


Route::prefix('auth')->controller(AuthController::class)->group(function () {
    Route::post('/register', 'register');
    Route::post('/login', 'login');
    Route::get('/verify-email', 'verifyEmail'); // 👈 جديد
    Route::post('/logout', 'logout')->middleware('auth:sanctum'); // لو عندك logout
});

Route::middleware('auth:sanctum')->group(function () {

    // 🟢 user side
    Route::post('/organizer-requests', [OrganizerRequestController::class, 'store']);
    Route::get('/organizer-requests/me', [OrganizerRequestController::class, 'myRequests']);

    // 🔴 admin side
    Route::prefix('admin')->group(function () {
    Route::get('/organizer-requests', [OrganizerRequestAdminController::class, 'index']);
    Route::post('/organizer-requests/{id}/approve', [OrganizerRequestAdminController::class, 'approve']);
    Route::post('/organizer-requests/{id}/reject', [OrganizerRequestAdminController::class, 'reject']);
});

Route::middleware('auth:sanctum')->group(function () {

    // ...

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
});



});


