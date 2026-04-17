<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Http\Resources\ProductResource;
use App\Models\Category;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/categories
     */
    public function index(Request $request): JsonResponse
    {
        $categories = Category::active()
            ->topLevel()
            ->with('children')
            ->withCount('products')
            ->orderBy('sort_order')
            ->paginate(20);

        return $this->paginated($categories, CategoryResource::collection($categories));
    }

    /**
     * GET /api/v1/categories/{id}/products
     */
    public function products(Request $request, int $id): JsonResponse
    {
        $category = Category::active()->findOrFail($id);

        $products = $category->products()
            ->available()
            ->with('category')
            ->when($request->search, fn($q) => $q->where(function ($q) use ($request) {
                $q->where('name_en', 'like', "%{$request->search}%")
                  ->orWhere('name_ar', 'like', "%{$request->search}%");
            }))
            ->orderBy('sort_order')
            ->paginate(20);

        return $this->paginated($products, ProductResource::collection($products));
    }
}
