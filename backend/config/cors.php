<?php

/**
 * CORS is handled entirely by nginx.
 * Setting paths to an empty array disables Laravel's HandleCors middleware
 * so we never get duplicate Access-Control-Allow-Origin headers.
 */
return [
    'paths'                    => [],
    'allowed_methods'          => ['*'],
    'allowed_origins'          => ['*'],
    'allowed_origins_patterns' => [],
    'allowed_headers'          => ['*'],
    'exposed_headers'          => [],
    'max_age'                  => 0,
    'supports_credentials'     => false,
];
