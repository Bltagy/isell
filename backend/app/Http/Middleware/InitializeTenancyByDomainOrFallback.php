<?php

namespace App\Http\Middleware;

use Closure;
use Stancl\Tenancy\Middleware\InitializeTenancyByDomain;
use App\Models\Domain;

/**
 * Extends the standard domain tenancy middleware to:
 *  1. Skip identification for IP addresses (mobile dev / LAN access).
 *  2. Fall back to the first available tenant when no domain match is found,
 *     so the app still works during local development.
 */
class InitializeTenancyByDomainOrFallback extends InitializeTenancyByDomain
{
    public function handle($request, Closure $next)
    {
        $host = $request->getHost();

        // Skip tenancy for IP addresses — treat as central / dev access
        if (filter_var($host, FILTER_VALIDATE_IP)) {
            return $this->initializeFallbackTenant($request, $next);
        }

        // For central domains (localhost etc.) also use fallback tenant
        // so the dashboard and mobile app both work without a real domain
        if (in_array($host, config('tenancy.central_domains', []), true)) {
            return $this->initializeFallbackTenant($request, $next);
        }

        // Try normal domain-based identification
        $domain = Domain::where('domain', $host)->first();

        if ($domain) {
            return parent::handle($request, $next);
        }

        // No domain found — fall back to first tenant (dev convenience)
        return $this->initializeFallbackTenant($request, $next);
    }

    protected function initializeFallbackTenant($request, Closure $next)
    {
        $domain = Domain::with('tenant')->first();

        if ($domain && $domain->tenant) {
            tenancy()->initialize($domain->tenant);
            // Set default DB connection to tenant so Sanctum resolves tokens correctly
            config(['database.default' => 'tenant']);
            $response = $next($request);
            tenancy()->end();
            return $response;
        }

        // No tenant at all — pass through (central routes will handle it)
        return $next($request);
    }
}
