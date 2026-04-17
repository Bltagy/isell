<?php

use App\Http\Controllers\Api\V1\AddressController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CategoryController;
use App\Http\Controllers\Api\V1\FavoriteController;
use App\Http\Controllers\Api\V1\HomeController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\OfferController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\ProductController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ReviewController;
use App\Http\Controllers\Api\V1\SettingsController;
use App\Http\Controllers\Api\V1\Admin\AdminBannerController;
use App\Http\Controllers\Api\V1\Admin\AdminCustomerController;
use App\Http\Controllers\Api\V1\Admin\AdminDriverController;
use App\Http\Controllers\Api\V1\Admin\AdminNotificationController;
use App\Http\Controllers\Api\V1\Admin\AdminOfferController;
use App\Http\Controllers\Api\V1\Admin\AdminOrderController;
use App\Http\Controllers\Api\V1\Admin\AdminProductController;
use App\Http\Controllers\Api\V1\Admin\AdminSettingsController;
use App\Http\Controllers\Api\V1\Admin\DashboardController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {

    // ─── Public ───────────────────────────────────────────────
    Route::middleware('throttle:public-api')->group(function () {

    Route::get('settings/app-config', [SettingsController::class, 'appConfig']);
    Route::get('settings/about',      [SettingsController::class, 'about']);
    Route::get('settings/help',       [SettingsController::class, 'help']);
    Route::get('home', [HomeController::class, 'index']);

    // ─── Auth ─────────────────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('register',       [AuthController::class, 'register']);
        Route::post('login',          [AuthController::class, 'login']);
        Route::post('send-otp',       [AuthController::class, 'sendOtp']);
        Route::post('resend-otp',     [AuthController::class, 'sendOtp']);
        Route::post('verify-otp',     [AuthController::class, 'verifyOtp']);
        Route::post('forgot-password',[AuthController::class, 'forgotPassword']);
        Route::post('reset-password', [AuthController::class, 'resetPassword']);

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('logout',        [AuthController::class, 'logout']);
            Route::post('refresh-token', [AuthController::class, 'refreshToken']);
        });
    });

    // ─── Categories ───────────────────────────────────────────
    Route::get('categories',                  [CategoryController::class, 'index']);
    Route::get('categories/{id}/products',    [CategoryController::class, 'products']);

    // ─── Products ─────────────────────────────────────────────
    Route::get('products',                    [ProductController::class, 'index']);
    Route::get('products/{id}',               [ProductController::class, 'show']);
    Route::get('products/{id}/reviews',       [ProductController::class, 'reviews']);

    // ─── Offers ───────────────────────────────────────────────
    Route::post('offers/validate-code',       [OfferController::class, 'validateCode']);
    Route::get('offers',                      [OfferController::class, 'index']);

    // ─── Payments (webhook — no auth) ─────────────────────────
    Route::post('payments/kashier-webhook',   [PaymentController::class, 'kashierWebhook']);

    // ─── Debug / error reporting (only active when APP_DEBUG=true) ─────
    Route::post('debug/report', [\App\Http\Controllers\Api\V1\DebugController::class, 'report']);

    }); // end throttle:public-api

    // ─── Authenticated ────────────────────────────────────────
    Route::middleware(['auth:sanctum', 'throttle:authenticated-api'])->group(function () {

        // Payments
        Route::post('payments/initiate',          [PaymentController::class, 'initiate']);

        // Orders
        Route::post('orders',                 [OrderController::class, 'store']);
        Route::get('orders',                  [OrderController::class, 'index']);
        Route::get('orders/{id}',             [OrderController::class, 'show']);
        Route::post('orders/{id}/cancel',     [OrderController::class, 'cancel']);
        Route::post('orders/{id}/reorder',    [OrderController::class, 'reorder']);
        Route::get('orders/{id}/track',       [OrderController::class, 'track']);

        // Profile
        Route::get('profile',                 [ProfileController::class, 'show']);
        Route::put('profile',                 [ProfileController::class, 'update']);
        Route::put('profile/update-fcm-token',[ProfileController::class, 'updateFcmToken']);

        // Addresses
        Route::get('addresses',               [AddressController::class, 'index']);
        Route::post('addresses',              [AddressController::class, 'store']);
        Route::put('addresses/{id}',          [AddressController::class, 'update']);
        Route::delete('addresses/{id}',       [AddressController::class, 'destroy']);
        Route::put('addresses/{id}/set-default', [AddressController::class, 'setDefault']);

        // Notifications
        Route::get('notifications',              [NotificationController::class, 'index']);
        Route::patch('notifications/{id}/read',  [NotificationController::class, 'markRead']);
        Route::post('notifications/read-all',    [NotificationController::class, 'markAllRead']);
        Route::get('notifications/unread-count', [NotificationController::class, 'unreadCount']);

        // Favorites
        Route::get('favorites',                         [FavoriteController::class, 'index']);
        Route::post('favorites/{productId}',            [FavoriteController::class, 'add']);
        Route::delete('favorites/{productId}',          [FavoriteController::class, 'remove']);
        Route::post('favorites/{productId}/toggle',     [FavoriteController::class, 'toggle']);

        // Reviews
        Route::post('reviews',                [ReviewController::class, 'store']);
    });

    // ─── Admin ────────────────────────────────────────────────
    Route::prefix('admin')
        ->middleware(['auth:sanctum', 'throttle:authenticated-api', 'role:Tenant_Admin|Branch_Manager'])
        ->group(function () {

            // Dashboard
            Route::get('dashboard',           [DashboardController::class, 'stats']);

            // Orders
            Route::get('orders',              [AdminOrderController::class, 'index']);
            Route::get('orders/{id}',         [AdminOrderController::class, 'show']);
            Route::put('orders/{id}/status',  [AdminOrderController::class, 'updateStatus']);
            Route::put('orders/{id}/assign-driver', [AdminOrderController::class, 'assignDriver']);

            // Categories
            Route::get('categories',          [AdminProductController::class, 'indexCategories']);
            Route::post('categories',         [AdminProductController::class, 'storeCategory']);
            Route::put('categories/{id}',     [AdminProductController::class, 'updateCategory']);
            Route::delete('categories/{id}',  [AdminProductController::class, 'destroyCategory']);

            // Products
            Route::get('products',                    [AdminProductController::class, 'indexProducts']);
            Route::get('products/{id}',               [AdminProductController::class, 'showProduct']);
            Route::post('products',                   [AdminProductController::class, 'storeProduct']);
            Route::put('products/{id}',               [AdminProductController::class, 'updateProduct']);
            Route::delete('products/{id}',            [AdminProductController::class, 'destroyProduct']);
            Route::post('products/{id}/images',       [AdminProductController::class, 'uploadImages']);
            Route::post('products/bulk-toggle',       [AdminProductController::class, 'bulkToggle']);
            Route::post('products/import',            [AdminProductController::class, 'importCsv']);

            // Customers
            Route::get('customers',           [AdminCustomerController::class, 'index']);
            Route::get('customers/{id}',      [AdminCustomerController::class, 'show']);
            Route::put('customers/{id}',      [AdminCustomerController::class, 'update']);
            Route::put('customers/{id}/toggle-status', [AdminCustomerController::class, 'toggleStatus']);
            Route::delete('customers/{id}',   [AdminCustomerController::class, 'destroy']);

            // Drivers
            Route::get('drivers',             [AdminDriverController::class, 'index']);
            Route::post('drivers',            [AdminDriverController::class, 'store']);
            Route::put('drivers/{id}',        [AdminDriverController::class, 'update']);
            Route::delete('drivers/{id}',     [AdminDriverController::class, 'destroy']);

            // Offers
            Route::get('offers',              [AdminOfferController::class, 'index']);
            Route::post('offers',             [AdminOfferController::class, 'store']);
            Route::put('offers/{id}',         [AdminOfferController::class, 'update']);
            Route::delete('offers/{id}',      [AdminOfferController::class, 'destroy']);

            // Banners
            Route::get('banners',             [AdminBannerController::class, 'index']);
            Route::post('banners',            [AdminBannerController::class, 'store']);
            Route::put('banners/{id}',        [AdminBannerController::class, 'update']);
            Route::delete('banners/{id}',     [AdminBannerController::class, 'destroy']);

            // Notifications
            Route::post('notifications/broadcast', [AdminNotificationController::class, 'broadcast']);

            // Settings
            Route::get('settings',                    [AdminSettingsController::class, 'index']);
            Route::post('settings/batch-update',      [AdminSettingsController::class, 'batchUpdate']);
            Route::post('settings/upload-image',      [AdminSettingsController::class, 'uploadImage']);
            Route::get('settings/faq',                [AdminSettingsController::class, 'getFaq']);
            Route::post('settings/faq',               [AdminSettingsController::class, 'saveFaq']);

            // Analytics
            Route::get('analytics/revenue',           [DashboardController::class, 'revenueAnalytics']);
            Route::get('analytics/heatmap',           [DashboardController::class, 'heatmap']);
        });
});
