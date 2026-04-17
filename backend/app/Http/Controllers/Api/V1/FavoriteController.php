<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProductResource;
use App\Models\Favorite;
use App\Models\Product;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $products = $request->user()->favoriteProducts()->with('category')->paginate(20);

        return $this->paginated($products, ProductResource::collection($products));
    }

    public function add(Request $request, int $productId): JsonResponse
    {
        Product::findOrFail($productId);

        Favorite::firstOrCreate([
            'user_id'    => $request->user()->id,
            'product_id' => $productId,
        ]);

        return $this->success(['is_favorited' => true], 'Added to favorites', 201);
    }

    public function remove(Request $request, int $productId): JsonResponse
    {
        Favorite::where('user_id', $request->user()->id)
            ->where('product_id', $productId)
            ->delete();

        return $this->success(['is_favorited' => false], 'Removed from favorites');
    }

    public function toggle(Request $request, int $productId): JsonResponse
    {
        Product::findOrFail($productId);

        $existing = Favorite::where('user_id', $request->user()->id)
            ->where('product_id', $productId)
            ->first();

        if ($existing) {
            $existing->delete();
            return $this->success(['is_favorited' => false], 'Removed from favorites');
        }

        Favorite::create(['user_id' => $request->user()->id, 'product_id' => $productId]);

        return $this->success(['is_favorited' => true], 'Added to favorites');
    }
}
