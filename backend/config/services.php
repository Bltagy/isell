<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'resend' => [
        'key' => env('RESEND_KEY'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // ─── Kashier Payment Gateway ──────────────────────────────
    'kashier' => [
        'merchant_id'    => env('KASHIER_MERCHANT_ID', ''),
        'api_key'        => env('KASHIER_API_KEY', ''),
        'mode'           => env('KASHIER_MODE', 'test'),
        'base_url'       => env('KASHIER_BASE_URL', 'https://checkout.kashier.io'),
        'webhook_secret' => env('KASHIER_WEBHOOK_SECRET', ''),
    ],

    // ─── Firebase ─────────────────────────────────────────────
    'firebase' => [
        'credentials' => env('FIREBASE_CREDENTIALS', storage_path('app/firebase-credentials.json')),
    ],

];
