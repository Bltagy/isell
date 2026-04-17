<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CentralAdminAuth
{
    public function handle(Request $request, Closure $next): mixed
    {
        if (! Auth::guard('central')->check()) {
            return redirect()->route('central.login');
        }

        return $next($request);
    }
}
