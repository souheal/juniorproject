<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
    ];

    // Events many-to-many
    public function events()
    {
        return $this->belongsToMany(Event::class, 'category_event');
    }

    // Users preferences many-to-many (لو عندك جدول category_user)
    public function users()
    {
        return $this->belongsToMany(User::class, 'category_user');
    }
}
