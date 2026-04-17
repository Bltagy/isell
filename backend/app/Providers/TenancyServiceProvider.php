<?php

declare(strict_types=1);

namespace App\Providers;

use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Stancl\JobPipeline\JobPipeline;
use Stancl\Tenancy\Events;
use Stancl\Tenancy\Jobs;
use Stancl\Tenancy\Listeners;
use Stancl\Tenancy\Middleware;

class TenancyServiceProvider extends ServiceProvider
{
    public function events(): array
    {
        return [
            // ── Tenant lifecycle ──────────────────────────────
            Events\TenantCreated::class => [
                JobPipeline::make([
                    Jobs\CreateDatabase::class,
                    Jobs\MigrateDatabase::class,
                ])->send(fn(Events\TenantCreated $e) => $e->tenant)->shouldBeQueued(false),
            ],
            Events\TenantDeleted::class => [
                JobPipeline::make([
                    Jobs\DeleteDatabase::class,
                ])->send(fn(Events\TenantDeleted $e) => $e->tenant)->shouldBeQueued(false),
            ],

            // ── Tenancy bootstrap/revert (CRITICAL) ───────────
            Events\TenancyInitialized::class => [
                Listeners\BootstrapTenancy::class,
            ],
            Events\TenancyEnded::class => [
                Listeners\RevertToCentralContext::class,
            ],
        ];
    }

    public function register(): void {}

    public function boot(): void
    {
        foreach ($this->events() as $event => $listeners) {
            foreach ($listeners as $listener) {
                Event::listen($event, $listener);
            }
        }

        $this->makeTenancyMiddlewareHighestPriority();
    }

    protected function makeTenancyMiddlewareHighestPriority(): void
    {
        $tenancyMiddleware = [
            Middleware\InitializeTenancyByDomain::class,
            Middleware\InitializeTenancyBySubdomain::class,
            Middleware\InitializeTenancyByDomainOrSubdomain::class,
        ];

        foreach (array_reverse($tenancyMiddleware) as $middleware) {
            app(\Illuminate\Contracts\Http\Kernel::class)->prependToMiddlewarePriority($middleware);
        }
    }
}
