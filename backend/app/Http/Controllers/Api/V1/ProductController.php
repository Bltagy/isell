<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProductResource;
use App\Http\Resources\ReviewResource;
use App\Models\Product;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Laravel\Scout\Builder;

class ProductController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/products
     */
    public function index(Request $request): JsonResponse
    {
        // Use Meilisearch if search term provided
        if ($request->filled('search')) {
            $results = Product::search($request->search)
                ->when($request->category_id, fn(Builder $b) => $b->where('category_id', (int) $request->category_id))
                ->when($request->boolean('is_featured'), fn(Builder $b) => $b->where('is_featured', true))
                ->paginate(20);

            return $this->paginated($results, ProductResource::collection($results));
        }

        $products = Product::available()
            ->with('category')
            ->when($request->category_id, fn($q) => $q->where('category_id', $request->category_id))
            ->when($request->boolean('is_featured'), fn($q) => $q->featured())
            ->when($request->min_price, fn($q) => $q->where('price', '>=', (int) $request->min_price))
            ->when($request->max_price, fn($q) => $q->where('price', '<=', (int) $request->max_price))
            ->when($request->sort_by, function ($q) use ($request) {
                match ($request->sort_by) {
                    'price_asc'  => $q->orderBy('price'),
                    'price_desc' => $q->orderByDesc('price'),
                    'newest'     => $q->latest(),
                    default      => $q->orderBy('sort_order'),
                };
            }, fn($q) => $q->orderBy('sort_order'))
            ->paginate(20);

        return $this->paginated($products, ProductResource::collection($products));
    }

    /**
     * GET /api/v1/products/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $product = Product::available()
            ->with(['category', 'options.items', 'reviews'])
            ->findOrFail($id);

        // Attach favorite status for authenticated users
        if ($request->user()) {
            $product->is_favorited = $request->user()
                ->favorites()
                ->where('product_id', $product->id)
                ->exists();
        }

        return $this->success(new ProductResource($product));
    }

    /**
     * GET /api/v1/products/{id}/reviews
     */
    public function reviews(int $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $reviews = $product->reviews()->with('user')->latest()->paginate(20);

        return $this->paginated($reviews, ReviewResource::collection($reviews));
    }
}
