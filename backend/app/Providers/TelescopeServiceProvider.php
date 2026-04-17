<?php

namespace App\Providers;

use Illuminate\Support\Facades\Gate;
use Laravel\Telescope\IncomingEntry;
use Laravel\Telescope\Telescope;
use Laravel\Telescope\TelescopeApplicationServiceProvider;

class TelescopeServiceProvider extends TelescopeApplicationServiceProvider
{
    public function register(): void
    {
        $this->hideSensitiveRequestDetails();

        // In local env record everything; in production only record failures.
        $isLocal = $this->app->environment('local');

        Telescope::filter(function (IncomingEntry $entry) use ($isLocal) {
            return $isLocal
                || $entry->isReportableException()
                || $entry->isFailedRequest()
                || $entry->isFailedJob()
                || $entry->isScheduledTask()
                || $entry->hasMonitoredTag();
        });

        // Always store Telescope data in the central DB connection,
        // never in a tenant DB — even when a tenant request is active.
        Telescope::afterRecording(function () {
            // no-op: storage connection is set via config/telescope.php
        });
    }

    protected function hideSensitiveRequestDetails(): void
    {
        Telescope::hideRequestParameters(['password', 'password_confirmation']);
        Telescope::hideRequestHeaders(['authorization', 'cookie', 'x-csrf-token', 'x-xsrf-token']);
    }

    protected function gate(): void
    {
        Gate::define('viewTelescope', function ($user = null) {
            // Allow all access in local environment (no auth required).
            if (app()->environment('local')) {
                return true;
            }
            // In production restrict to specific emails.
            return $user && in_array($user->email, [
                'admin@foodapp.com',
            ]);
        });
    }
}
