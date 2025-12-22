<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'role_id',
        'name',
        'email',
        'phone',
        'location',
        'picture',
        'birth_date',
        'password',
        'email_verification_token',
        'otp_expires_at',
        'last_login_ip',
        'notifications_enabled',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at'     => 'datetime',
            'otp_expires_at'        => 'datetime',
            'password'              => 'hashed',
            'notifications_enabled' => 'boolean',
        ];
    }

    // ========== Relationships ==========

    // Preferred categories of the user
    public function categories()
    {
        return $this->belongsToMany(Category::class, 'category_user');
    }

    // Requests to become organizer
    public function organizerRequests()
    {
        return $this->hasMany(OrganizerRequest::class);
    }

    // Role: user / organizer / admin
    public function role()
    {
        return $this->belongsTo(Role::class);
    }

    // Custom notifications table (your Notification model)
    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    // Volunteer requests this user submitted
    public function volunteerRequests()
    {
        return $this->hasMany(VolunteerRequest::class);
    }

    // Extra info if user is organizer
    public function organizerProfile()
    {
        return $this->hasOne(OrganizerProfile::class, 'user_id');
    }

    // ========= New for profile features =========

    // Events the user has saved (favorites)
    public function savedEvents()
    {
        return $this->belongsToMany(Event::class, 'saved_events')
                    ->withTimestamps();
    }

    // Tickets owned by the user (used for stats & "My Tickets")
    public function tickets()
    {
        return $this->hasMany(Ticket::class);
    }
}
