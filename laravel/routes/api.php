<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\PublicEventController;
use App\Http\Controllers\Api\ManageEventController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\User\OrganizerRequestController;
use App\Http\Controllers\Admin\OrganizerRequestAdminController;
use App\Http\Controllers\User\VolunteerRequestController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\OrganizerEventStatsController;

// ✅ NEW: volunteer opportunities browse endpoints
use App\Http\Controllers\Api\VolunteerOpportunitiesController;

// =====================
// Auth routes (public)
// =====================
Route::prefix('auth')->group(function () {

Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/verify-email-code', [AuthController::class, 'verifyEmailCode']);
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
    // Password reset
    Route::post('/password/forgot', [PasswordResetController::class, 'requestReset']);
    Route::post('/password/reset',  [PasswordResetController::class, 'reset']);
});

// =====================
// Public: Events + Categories (Flutter user)
// =====================
Route::get('/events',         [PublicEventController::class, 'index']);
Route::get('/events/{event}', [PublicEventController::class, 'show']);

Route::get('/categories', [CategoryController::class, 'index']);

// =====================
// ✅ Public: Volunteer Opportunities browse
// =====================
Route::get('/volunteer/opportunities', [VolunteerOpportunitiesController::class, 'index']);
Route::get('/volunteer/opportunities/{event}', [VolunteerOpportunitiesController::class, 'showEvent']);
Route::get('/volunteer/opportunities/{event}/roles/{type}', [VolunteerOpportunitiesController::class, 'roleDetails']);

// =====================
// Stripe webhook (PUBLIC, بدون auth)
// =====================
Route::post('/payments/stripe/webhook', [PaymentController::class, 'webhook']);

// =====================
// Protected routes (need login)
// =====================
Route::middleware('auth:sanctum')->group(function () {

    // ---------- Auth ----------
    Route::get('/auth/me', [AuthController::class, 'me']);

    // ---------- PROFILE / ACCOUNT DASHBOARD ----------
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::post('/profile/change-password', [ProfileController::class, 'changePassword']);
    Route::delete('/profile', [ProfileController::class, 'deleteAccount']);
    Route::post('/profile/notifications', [ProfileController::class, 'updateNotifications']);
    Route::get('/profile/tickets',      [ProfileController::class, 'tickets']);
    Route::get('/profile/saved-events', [ProfileController::class, 'savedEvents']);
    Route::post('/events/{event}/save',   [ProfileController::class, 'saveEvent']);
    Route::delete('/events/{event}/save', [ProfileController::class, 'unsaveEvent']);

    // ---------- Organizer Request – user ----------
    Route::post('/organizer-requests',   [OrganizerRequestController::class, 'store']);
    Route::get('/organizer-requests/me', [OrganizerRequestController::class, 'myRequests']);

    // ---------- Organizer Request – admin ----------
    // ADMIN ONLY: All routes in this group require admin role
    Route::prefix('admin')->middleware('admin')->group(function () {
        Route::get('/organizer-requests',               [OrganizerRequestAdminController::class, 'index']);
        Route::post('/organizer-requests/{id}/approve', [OrganizerRequestAdminController::class, 'approve']);
        Route::post('/organizer-requests/{id}/reject',  [OrganizerRequestAdminController::class, 'reject']);

        // Admin events delete
        Route::delete('/events/{id}', [ManageEventController::class, 'destroy']);
    });

    // ---------- Notifications ----------
    Route::get('/notifications',              [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read',   [NotificationController::class, 'markAsRead']);

    // ---------- Organizer: manage own events ----------
    Route::prefix('organizer')->group(function () {

        // CRUD للأحداث تبع المنظم
        Route::get('/events',      [ManageEventController::class, 'index']);
        Route::post('/events',     [ManageEventController::class, 'store']);
        Route::put('/events/{id}', [ManageEventController::class, 'update']);

        // Dashboard + tickets لكل حدث
        Route::get('/events/{event}/dashboard', [OrganizerEventStatsController::class, 'dashboard']);
        Route::get('/events/{event}/tickets',   [OrganizerEventStatsController::class, 'tickets']);

        // Volunteer requests على أحداثه
        Route::get('/volunteer-requests',               [VolunteerRequestController::class, 'organizerIndex']);
        Route::post('/volunteer-requests/{id}/approve', [VolunteerRequestController::class, 'approve']);
        Route::post('/volunteer-requests/{id}/reject',  [VolunteerRequestController::class, 'reject']);

        // Scan للـ QR عند الباب
        Route::post('/tickets/scan', [TicketController::class, 'scan']);
    });

    // ---------- User: volunteer requests ----------
    Route::post('/events/{event}/volunteer-requests', [VolunteerRequestController::class, 'store']);
    Route::get('/volunteer-requests/me',              [VolunteerRequestController::class, 'myRequests']);

    // ---------- Ticketing / Payments ----------
    Route::post('/events/{event}/checkout', [PaymentController::class, 'checkout']);
    Route::get('/my-tickets', [TicketController::class, 'myTickets']);
});
