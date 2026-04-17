<?php

namespace App\Models;

use Laravel\Sanctum\PersonalAccessToken as SanctumPersonalAccessToken;

class PersonalAccessToken extends SanctumPersonalAccessToken
{
    /**
     * Always resolve the connection dynamically so Sanctum uses
     * the tenant DB (switched by tenancy middleware) instead of
     * the central DB when authenticating API requests.
     */
    public function getConnectionName(): ?string
    {
        // If tenancy is initialized, use the current tenant connection
        if (app()->bound('tenancy') && tenancy()->initialized) {
            return config('database.default');
        }

        return parent::getConnectionName();
    }
}
