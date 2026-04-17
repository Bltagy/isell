<?php

namespace App\Jobs\Concerns;

/**
 * Add to any queued job/listener that needs tenant context.
 * Stores the tenant ID at dispatch time and restores it at execution time.
 */
trait TenantAware
{
    public string $tenantId = '';

    public function initializeTenantAware(): void
    {
        if (tenancy()->initialized) {
            $this->tenantId = (string) tenant('id');
        }
    }

    public function withTenantContext(callable $callback): mixed
    {
        if (!$this->tenantId) {
            return $callback();
        }

        $tenant = \App\Models\Tenant::find($this->tenantId);

        if (!$tenant) {
            return $callback();
        }

        // Initialize tenancy, run callback, then end
        tenancy()->initialize($tenant);

        try {
            return $callback();
        } finally {
            tenancy()->end();
        }
    }
}
