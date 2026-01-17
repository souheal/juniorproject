<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrganizerProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'organization_category_id',
        'organization_name',
        'description',
        'contact_email',
        'contact_phone',
        'website',
        'logo',
        'facebook',
        'instagram',
        'twitter',
        'verified',
    ];

    protected function casts(): array
    {
        return [
            //encrypt phone at rest
            'contact_phone' => 'encrypted',
            'verified' => 'boolean',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
