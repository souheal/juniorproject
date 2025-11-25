<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Category extends Model
{
    use HasFactory;

    // IMPORTANT: our categories table has no created_at / updated_at columns
    public $timestamps = false;

    protected $fillable = [
        'name',
    ];

    public function users()
    {
        return $this->belongsToMany(User::class, 'category_user');
    }

    public function events()
    {
        return $this->belongsToMany(Event::class, 'category_event');
    }
}
