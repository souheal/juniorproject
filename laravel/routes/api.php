<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;


// SIGNUP ROUTE
Route::post('/signup', [AuthController::class, 'register']);
