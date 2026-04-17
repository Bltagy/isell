<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;
use Illuminate\Pagination\LengthAwarePaginator;

trait ApiResponse
{
    /**
     * Success response.
     */
    protected function success(mixed $data = null, string $message = 'Operation successful', int $status = 200): JsonResponse
    {
        $response = [
            'success' => true,
            'message' => $message,
            'data'    => $data,
        ];

        return response()->json($response, $status);
    }

    /**
     * Paginated success response.
     */
    protected function paginated(LengthAwarePaginator $paginator, mixed $data, string $message = 'Operation successful'): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data'    => $data,
            'meta'    => [
                'current_page' => $paginator->currentPage(),
                'last_page'    => $paginator->lastPage(),
                'per_page'     => $paginator->perPage(),
                'total'        => $paginator->total(),
                'from'         => $paginator->firstItem(),
                'to'           => $paginator->lastItem(),
            ],
        ]);
    }

    /**
     * Error response.
     */
    protected function error(string $message, int $status = 400, array $errors = []): JsonResponse
    {
        $response = [
            'success' => false,
            'message' => $message,
        ];

        if (!empty($errors)) {
            $response['errors'] = $errors;
        }

        return response()->json($response, $status);
    }

    /**
     * Money array helper.
     */
    protected function moneyArray(int $piastres, string $field = 'price'): array
    {
        return [
            "{$field}_piastres"  => $piastres,
            "{$field}_egp"       => number_format($piastres / 100, 2),
            "{$field}_formatted" => number_format($piastres / 100, 2).' ج.م',
        ];
    }
}
