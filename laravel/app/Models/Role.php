<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Role extends Model
{
    use HasFactory;

    // IMPORTANT: your roles table has no created_at / updated_at columns
    public $timestamps = false;

    protected $fillable = [
        'name',
    ];
}
