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
        'start_time',
        'end_time',
        'is_live',    
        'city',   
        'location',    
        'venue',       
        'capacity',
        'price',
        'online_link',
        'picture',
    ];

    protected $casts = [
        'start_time' => 'datetime',
        'end_time'   => 'datetime',
        'is_live'    => 'boolean',
    ];

    public function organizer()
    {
        return $this->belongsTo(User::class, 'organizer_id');
    }

    public function categories()
    {
        return $this->belongsToMany(Category::class, 'event_category');
    }
}
