<?php

use App\Http\Controllers\Central\CentralDashboardController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json(['status' => 'Food App API', 'version' => '1.0']);
});

Route::get('/up', function () {
    return response()->json(['status' => 'ok']);
});

/*
|--------------------------------------------------------------------------
| Central Admin Panel (Blade)
|--------------------------------------------------------------------------
*/
Route::prefix('panel')->name('central.')->group(function () {

    // Auth
    Route::get('login',  [\App\Http\Controllers\Central\CentralAuthController::class, 'showLogin'])->name('login');
    Route::post('login', [\App\Http\Controllers\Central\CentralAuthController::class, 'login'])->name('login.post');
    Route::post('logout',[\App\Http\Controllers\Central\CentralAuthController::class, 'logout'])->name('logout');

    // Protected panel
    Route::middleware('central.auth')->group(function () {

        Route::get('/',          [CentralDashboardController::class, 'index'])->name('dashboard');

        // Tenants
        Route::get('tenants',                    [CentralDashboardController::class, 'tenants'])->name('tenants');
        Route::get('tenants/create',             [CentralDashboardController::class, 'createTenant'])->name('tenants.create');
        Route::post('tenants',                   [CentralDashboardController::class, 'storeTenant'])->name('tenants.store');
        Route::get('tenants/{id}',               [CentralDashboardController::class, 'showTenant'])->name('tenants.show');
        Route::post('tenants/{id}/suspend',      [CentralDashboardController::class, 'suspendTenant'])->name('tenants.suspend');
        Route::post('tenants/{id}/activate',     [CentralDashboardController::class, 'activateTenant'])->name('tenants.activate');
        Route::delete('tenants/{id}',            [CentralDashboardController::class, 'destroyTenant'])->name('tenants.destroy');
        Route::post('tenants/{id}/assign-plan',  [CentralDashboardController::class, 'assignPlan'])->name('tenants.assign-plan');

        // Tenant info update
        Route::put('tenants/{id}',               [CentralDashboardController::class, 'updateTenant'])->name('tenants.update');

        // Domain management
        Route::post('tenants/{id}/domains',                      [CentralDashboardController::class, 'storeDomain'])->name('tenants.domains.store');
        Route::put('tenants/{id}/domains/{domainId}',            [CentralDashboardController::class, 'updateDomain'])->name('tenants.domains.update');
        Route::post('tenants/{id}/domains/{domainId}/primary',   [CentralDashboardController::class, 'setPrimaryDomain'])->name('tenants.domains.primary');
        Route::delete('tenants/{id}/domains/{domainId}',         [CentralDashboardController::class, 'destroyDomain'])->name('tenants.domains.destroy');

        // Subscription management
        Route::put('tenants/{id}/subscriptions/{subId}',         [CentralDashboardController::class, 'updateSubscription'])->name('tenants.subscriptions.update');
        Route::delete('tenants/{id}/subscriptions/{subId}',      [CentralDashboardController::class, 'destroySubscription'])->name('tenants.subscriptions.destroy');

        // Plans
        Route::get('plans',          [CentralDashboardController::class, 'plans'])->name('plans');
        Route::post('plans',         [CentralDashboardController::class, 'storePlan'])->name('plans.store');
        Route::put('plans/{id}',     [CentralDashboardController::class, 'updatePlan'])->name('plans.update');
        Route::delete('plans/{id}',  [CentralDashboardController::class, 'destroyPlan'])->name('plans.destroy');
    });
});
