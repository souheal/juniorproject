<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ticket extends Model
{
    protected $fillable = [
        'event_id',
        'user_id',
        'qr_code',
        'is_scanned',
        'scanned_at',
        'payment_status',
    ];

    protected $casts = [
        'is_scanned' => 'boolean',
        'scanned_at' => 'datetime',
    ];

public function user()
{
    return $this->belongsTo(\App\Models\User::class);
}

public function event()
{
    return $this->belongsTo(\App\Models\Event::class);
}

    public function payment()
    {
        return $this->hasOne(Payment::class);
    }
}
