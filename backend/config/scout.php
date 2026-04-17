<?php

return [
    'driver' => env('SCOUT_DRIVER', 'meilisearch'),

    'prefix' => env('SCOUT_PREFIX', ''),

    'queue' => env('SCOUT_QUEUE', false),

    'after_commit' => false,

    'chunk' => [
        'searchable'   => 500,
        'unsearchable' => 500,
    ],

    'soft_delete' => false,

    'identify' => false,

    'meilisearch' => [
        'host' => env('MEILISEARCH_HOST', 'http://localhost:7700'),
        'key'  => env('MEILISEARCH_KEY', null),
        'index-settings' => [
            // Tenant-scoped product index settings are applied dynamically
            // via Product::searchableAs() which returns tenant_{id}_products
        ],
    ],
];
