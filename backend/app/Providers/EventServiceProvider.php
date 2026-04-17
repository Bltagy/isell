<?php

namespace App\Providers;

use App\Events\OrderPlaced;
use App\Listeners\HandleOrderPlaced;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        OrderPlaced::class => [
            HandleOrderPlaced::class,
        ],
    ];

    public function boot(): void {}

    public function shouldDiscoverEvents(): bool
    {
        return true;
    }
}
