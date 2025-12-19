<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    use HasFactory;

    protected $fillable = [
    'organizer_id',
    'name',
    'description',
    'location',
    'city',
    'venue',
    'price',
    'capacity',
    'start_time',
    'end_time',
    'online_link',
    'picture',
    'status',
    'published_at',
    'is_live',
    'volunteer_needs', // ✅ ADD THIS
];


    protected $casts = [
        'start_time'   => 'datetime',
        'end_time'     => 'datetime',
        'published_at' => 'datetime',
        'is_live'      => 'boolean',
        'price'        => 'decimal:2',
        'volunteer_needs' => 'array',
    ];

    // organizer (user)
    public function organizer()
    {
        return $this->belongsTo(User::class, 'organizer_id');
    }

    // categories (pivot: category_event)
    public function categories()
    {
        return $this->belongsToMany(Category::class, 'category_event');
    }
    
    public function savedByUsers()
{
    return $this->belongsToMany(User::class, 'saved_events')
                ->withTimestamps();
}


    public function tickets()
    {
        return $this->hasMany(Ticket::class);
    }

    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    public function ratings()
    {
        return $this->hasMany(Rating::class);
    }

    public function volunteerRequests()
    {
        return $this->hasMany(VolunteerRequest::class);
    }
}
