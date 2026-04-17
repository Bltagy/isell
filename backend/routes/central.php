<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Central (Super Admin) Routes
|--------------------------------------------------------------------------
| These routes are accessible only on central domains (not tenant subdomains).
| They manage tenants, subscription plans, and platform-wide analytics.
*/

Route::prefix('central/api')->middleware(['auth:sanctum'])->group(function () {

    // ─── Tenants ──────────────────────────────────────────────
    Route::get('tenants',                   [\App\Http\Controllers\Api\V1\Admin\AdminTenantController::class, 'index']);
    Route::post('tenants',                  [\App\Http\Controllers\Api\V1\Admin\AdminTenantController::class, 'store']);
    Route::patch('tenants/{id}/suspend',    [\App\Http\Controllers\Api\V1\Admin\AdminTenantController::class, 'suspend']);
    Route::delete('tenants/{id}',           [\App\Http\Controllers\Api\V1\Admin\AdminTenantController::class, 'destroy']);

    // ─── Subscription Plans ───────────────────────────────────
    Route::get('plans',                     [\App\Http\Controllers\Api\V1\Admin\AdminPlanController::class, 'index']);
    Route::post('plans',                    [\App\Http\Controllers\Api\V1\Admin\AdminPlanController::class, 'store']);
    Route::put('plans/{id}',                [\App\Http\Controllers\Api\V1\Admin\AdminPlanController::class, 'update']);
    Route::delete('plans/{id}',             [\App\Http\Controllers\Api\V1\Admin\AdminPlanController::class, 'destroy']);

    // ─── Super Admin Dashboard ────────────────────────────────
    Route::get('dashboard',                 [\App\Http\Controllers\Api\V1\Admin\SuperAdminDashboardController::class, 'index']);
});
