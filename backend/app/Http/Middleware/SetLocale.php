<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class SetLocale
{
    public function handle(Request $request, Closure $next): mixed
    {
        $locale = $request->header('Accept-Language', 'ar');
        $locale = in_array($locale, ['en', 'ar']) ? $locale : 'ar';
        app()->setLocale($locale);

        return $next($request);
    }
}
