<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrganizerRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'organization_name',
        'description',
        'documents',
        'status',
        'admin_comment',
    ];

    // صاحب الطلب
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
