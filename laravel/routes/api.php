<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\User\OrganizerRequestController;
use App\Http\Controllers\Admin\OrganizerRequestAdminController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\User\VolunteerRequestController;
use App\Http\Controllers\Api\CategoryController;

// =====================
// Auth routes (public)
// =====================
Route::prefix('auth')->group(function () {

    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/signup', [AuthController::class, 'register']); 
    Route::post('/login', [AuthController::class, 'login']);

    Route::get('/verify-email', [AuthController::class, 'verifyEmail']);

    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

    // Password reset
    Route::post('/password/forgot', [PasswordResetController::class, 'requestReset']);
    Route::post('/password/reset', [PasswordResetController::class, 'reset']);
});

Route::get('/events/browse', [EventController::class, 'browse']);
Route::get('/categories', [CategoryController::class, 'index']);
// =====================
// Protected routes
// =====================
Route::middleware('auth:sanctum')->group(function () {

    // =====================
    // Organizer Request – user
    // =====================
    Route::post('/organizer-requests', [OrganizerRequestController::class, 'store']);
    Route::get('/organizer-requests/me', [OrganizerRequestController::class, 'myRequests']);

    // =====================
    // Organizer Request – admin
    // =====================
    Route::prefix('admin')->group(function () {
        Route::get('/organizer-requests', [OrganizerRequestAdminController::class, 'index']);
        Route::post('/organizer-requests/{id}/approve', [OrganizerRequestAdminController::class, 'approve']);
        Route::post('/organizer-requests/{id}/reject', [OrganizerRequestAdminController::class, 'reject']);
    });

    // =====================
    // Notifications
    // =====================
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);


    // =====================
    // Events (Organizer only)
    // =====================
    Route::prefix('events')->group(function () {

        Route::get('/', [EventController::class, 'index']);     // organizer events

        Route::post('/', [EventController::class, 'store']);    // create event
        Route::put('/{id}', [EventController::class, 'update']); // update event
    });

    // Admin delete event
    Route::prefix('admin')->group(function () {
        Route::delete('/events/{id}', [EventController::class, 'destroy']);
    });


    // =====================
    // Volunteer Requests
    // =====================

    // user → submit volunteer request
    Route::post('/events/{event}/volunteer-requests', [VolunteerRequestController::class, 'store']);

    // user → view my volunteer requests
    Route::get('/volunteer-requests/me', [VolunteerRequestController::class, 'myRequests']);

    // organizer → manage volunteer requests
    Route::prefix('organizer')->group(function () {
        Route::get('/volunteer-requests', [VolunteerRequestController::class, 'organizerIndex']);
        Route::post('/volunteer-requests/{id}/approve', [VolunteerRequestController::class, 'approve']);
        Route::post('/volunteer-requests/{id}/reject', [VolunteerRequestController::class, 'reject']);
    });

});
