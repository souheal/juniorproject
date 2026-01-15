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
use App\Http\Controllers\Admin\AdminController;
use App\Http\Controllers\User\VolunteerRequestController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\OrganizerEventStatsController;
use App\Http\Controllers\Api\OrganizerProfileController;

// ✅ NEW: volunteer opportunities browse endpoints
use App\Http\Controllers\Api\VolunteerOpportunitiesController;

// ✅ NEW: Admin Dashboard endpoints
use App\Http\Controllers\Admin\UserAdminController;
use App\Http\Controllers\Admin\EventAdminController;

// =====================
// Auth routes (public)
// =====================
Route::prefix('auth')->group(function () {

    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/signup',   [AuthController::class, 'register']);
    Route::post('/login',    [AuthController::class, 'login']);

    // Email verification
    Route::get('/verify-email',  [AuthController::class, 'verifyEmail']);  // Legacy link-based
    Route::post('/verify-otp',   [AuthController::class, 'verifyOtp']);    // New OTP-based
    Route::post('/resend-code',  [AuthController::class, 'resendCode']);   // Resend OTP

    Route::post('/logout', [AuthController::class, 'logout'])
        ->middleware('auth:sanctum');

    // Password reset
    Route::post('/password/forgot', [PasswordResetController::class, 'requestReset']);
    Route::post('/password/verify-otp', [PasswordResetController::class, 'verifyOtp']);
    Route::post('/password/reset', [PasswordResetController::class, 'resetPassword']);
});

// =====================
// Public routes (no login)
// =====================

// Public events feed / browse
Route::get('/events', [PublicEventController::class, 'index']);
Route::get('/events/{event}', [PublicEventController::class, 'show']);

// Categories
Route::get('/categories', [CategoryController::class, 'index']);

// Volunteer opportunities browse
Route::get('/volunteer-opportunities', [VolunteerOpportunitiesController::class, 'index']);

// =====================
// Payments Webhook (public)
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

    // ---------- Organizer request (apply to become organizer) ----------
    Route::post('/organizer-requests', [OrganizerRequestController::class, 'store']);
    Route::get('/organizer-requests/me', [OrganizerRequestController::class, 'myRequest']);

    // ---------- Admin (protected by 'admin' middleware) ----------
    Route::prefix('admin')->middleware('admin')->group(function () {

        // Dashboard
        Route::get('/dashboard', [AdminController::class, 'dashboard']);

        // Users management
        Route::get('/users', [UserAdminController::class, 'index']);
        Route::post('/users/{id}/role', [UserAdminController::class, 'updateRole']);
        Route::delete('/users/{id}', [UserAdminController::class, 'destroy']);

        // Events management
        Route::get('/events', [AdminController::class, 'events']);
        Route::delete('/events/{id}', [AdminController::class, 'deleteEvent']);

        // Organizer requests
        Route::get('/organizer-requests', [AdminController::class, 'organizerRequests']);
        Route::post('/organizer-requests/{id}/approve', [OrganizerRequestAdminController::class, 'approve']);
        Route::post('/organizer-requests/{id}/reject',  [OrganizerRequestAdminController::class, 'reject']);
    });

    // ---------- Notifications ----------
    Route::get('/notifications',              [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read',   [NotificationController::class, 'markAsRead']);

    // ---------- Organizer: manage own events ----------
    Route::prefix('organizer')->middleware('organizer')->group(function () {

        // Organizer profile (view + edit)
        Route::get('/profile', [OrganizerProfileController::class, 'show']);
        Route::put('/profile', [OrganizerProfileController::class, 'update']);

        // CRUD للأحداث تبع المنظم
        Route::get('/events',      [ManageEventController::class, 'index']);
        Route::post('/events',     [ManageEventController::class, 'store']);
        Route::put('/events/{id}', [ManageEventController::class, 'update']);

        // Dashboard + tickets لكل حدث
        Route::get('/events/{event}/dashboard', [OrganizerEventStatsController::class, 'dashboard']);
        Route::get('/events/{event}/tickets',   [OrganizerEventStatsController::class, 'tickets']);
        Route::get('/events/{event}/registrations/export', [OrganizerEventStatsController::class, 'exportRegistrations']);


        // Volunteer requests على أحداثه
        Route::get('/volunteer-requests',                [VolunteerRequestController::class, 'organizerIndex']);
        Route::get('/volunteer-requests/export',         [VolunteerRequestController::class, 'export']); // ✅ NEW CSV EXPORT
        Route::post('/volunteer-requests/{id}/approve',  [VolunteerRequestController::class, 'approve']);
        Route::post('/volunteer-requests/{id}/reject',   [VolunteerRequestController::class, 'reject']);

        // Scan للـ QR عند الباب
        Route::post('/tickets/scan', [TicketController::class, 'scan']);
    });

    // ---------- User: volunteer requests ----------
    Route::post('/events/{event}/volunteer-requests', [VolunteerRequestController::class, 'store']);
    Route::get('/volunteer-requests/me', [VolunteerRequestController::class, 'myRequests']);

    // ---------- Ticketing / Payments ----------
    Route::post('/events/{event}/checkout', [PaymentController::class, 'checkout']);
    Route::get('/my-tickets', [TicketController::class, 'myTickets']);
});
