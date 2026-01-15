<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VolunteerRequest extends Model
{
    protected $fillable = [
        'event_id',
        'user_id',
        'volunteer_type',
        'reward',
        'status',
        'rejection_reason',
        'reviewed_at',
        'reviewed_by',
    ];

    protected $casts = [
        'reviewed_at' => 'datetime',
    ];

    public function event()
    {
        return $this->belongsTo(Event::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
