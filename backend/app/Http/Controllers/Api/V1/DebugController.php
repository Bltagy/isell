<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DebugController extends Controller
{
    use ApiResponse;

    /**
     * POST /api/v1/debug/report
     *
     * Receives error/event reports from the Flutter mobile app.
     * Logs them so Telescope picks them up automatically.
     * Only active when APP_DEBUG=true.
     */
    public function report(Request $request): JsonResponse
    {
        if (! config('app.debug')) {
            return $this->success(null, 'ok');
        }

        $request->validate([
            'type'       => 'required|string|in:error,flutter_error,api_error,event',
            'message'    => 'required|string|max:2000',
            'stack'      => 'nullable|string|max:10000',
            'context'    => 'nullable|array',
            'app_version'=> 'nullable|string',
            'route'      => 'nullable|string',
            'timestamp'  => 'nullable|string',
        ]);

        $type    = $request->input('type');
        $message = $request->input('message');
        $context = array_merge(
            $request->input('context', []),
            [
                'type'        => $type,
                'stack'       => $request->input('stack'),
                'route'       => $request->input('route'),
                'app_version' => $request->input('app_version'),
                'timestamp'   => $request->input('timestamp'),
                'device_ip'   => $request->ip(),
            ]
        );

        // Log at the right level — Telescope watches all log channels
        match ($type) {
            'error', 'flutter_error' => Log::error("[MobileApp] $message", $context),
            'api_error'              => Log::warning("[MobileApp:API] $message", $context),
            default                  => Log::info("[MobileApp:Event] $message", $context),
        };

        return $this->success(null, 'reported');
    }
}
