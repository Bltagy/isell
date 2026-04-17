<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Laravel\Sanctum\Sanctum;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bind services
        $this->app->singleton(\App\Services\KashierService::class);
        $this->app->singleton(\App\Services\NotificationService::class);
        $this->app->singleton(\App\Services\AuthService::class);
        $this->app->singleton(\App\Services\OrderService::class);
    }

    public function boot(): void
    {
        // Use tenant-aware personal_access_tokens model
        Sanctum::usePersonalAccessTokenModel(\App\Models\PersonalAccessToken::class);

        // Rate limiters
        RateLimiter::for('public-api', function (Request $request) {
            return Limit::perMinute(60)->by($request->ip());
        });

        RateLimiter::for('authenticated-api', function (Request $request) {
            return Limit::perMinute(300)->by(optional($request->user())->id ?: $request->ip());
        });
    }
}
