<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\User\OrganizerRequestController;
use App\Http\Controllers\Admin\OrganizerRequestAdminController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\EventController;


// =====================
// Auth routes
// =====================
Route::prefix('auth')->group(function () {
    // signup / login
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/signup', [AuthController::class, 'register']); // alias للفلاتر
    Route::post('/login', [AuthController::class, 'login']);

    // email verification
    Route::get('/verify-email', [AuthController::class, 'verifyEmail']);

    // logout
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

    // password reset
    Route::post('/password/forgot', [PasswordResetController::class, 'requestReset']);
    Route::post('/password/reset', [PasswordResetController::class, 'reset']);
});

// =====================
// Protected routes (need auth:sanctum)
// =====================
Route::middleware('auth:sanctum')->group(function () {
    // 🟢 Organizer Request – user side
    Route::post('/organizer-requests', [OrganizerRequestController::class, 'store']);
    Route::get('/organizer-requests/me', [OrganizerRequestController::class, 'myRequests']);

    // 🔴 Organizer Request – admin side
    Route::prefix('admin')->group(function () {
        Route::get('/organizer-requests', [OrganizerRequestAdminController::class, 'index']);
        Route::post('/organizer-requests/{id}/approve', [OrganizerRequestAdminController::class, 'approve']);
        Route::post('/organizer-requests/{id}/reject', [OrganizerRequestAdminController::class, 'reject']);
    });

    // 🔔 Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
});



Route::middleware('auth:sanctum')->group(function () {

    // =====================
    // Organizer events
    // =====================
    Route::prefix('events')->group(function () {
        // organizer يشوف أحداثه
        Route::get('/', [EventController::class, 'index']);

        // create (organizer only)
        Route::post('/', [EventController::class, 'store']);

        // update (organizer فقط ومالك الحدث)
        Route::put('/{id}', [EventController::class, 'update']);
    });

    // =====================
    // Admin delete
    // =====================
    Route::prefix('admin')->group(function () {
        Route::delete('/events/{id}', [EventController::class, 'destroy']);
    });

    // باقي روتاتك (organizer requests, notifications, ...)

});
