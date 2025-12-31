<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureUserIsOrganizer
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if (!$user || !$user->role || $user->role->name !== 'organizer') {
            return response()->json(['message' => 'Only organizers can access this resource.'], 403);
        }

        return $next($request);
    }
}
