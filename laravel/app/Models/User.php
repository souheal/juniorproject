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
    'last_login_ip', // 👈 ضفنا هذا
];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed', // Laravel 11 auto-hash
        ];
    }

    // لو عندك علاقة categories:
    public function categories()
    {
        return $this->belongsToMany(Category::class, 'category_user');
    }

    public function organizerRequests()
    {
        return $this->hasMany(OrganizerRequest::class);
    }

    public function role()
    {
        return $this->belongsTo(Role::class);
    }

    public function notifications()
    {
        return $this->hasMany(\App\Models\Notification::class);
    }

    public function volunteerRequests()
    {
        return $this->hasMany(\App\Models\VolunteerRequest::class);
    }



}
