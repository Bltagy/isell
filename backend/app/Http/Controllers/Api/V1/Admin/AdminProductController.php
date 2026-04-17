<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Http\Resources\ProductResource;
use App\Models\Category;
use App\Models\Product;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AdminProductController extends Controller
{
    use ApiResponse;

    // ─── Categories ───────────────────────────────────────────

    public function indexCategories(): JsonResponse
    {
        $categories = Category::withTrashed()->with('children')->orderBy('sort_order')->get();
        return $this->success(CategoryResource::collection($categories));
    }

    public function storeCategory(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name_en'    => 'required|string',
            'name_ar'    => 'required|string',
            'parent_id'  => 'nullable|integer|exists:categories,id',
            'sort_order' => 'integer',
            'is_active'  => 'boolean',
            'image'      => 'nullable|image|max:2048',
        ]);

        if ($request->hasFile('image')) {
            $data['image'] = Storage::disk('s3')->url($request->file('image')->store('categories', 's3'));
        }

        $category = Category::create($data);

        return $this->success(new CategoryResource($category), 'Category created', 201);
    }

    public function updateCategory(Request $request, int $id): JsonResponse
    {
        $category = Category::findOrFail($id);

        $data = $request->validate([
            'name_en'    => 'sometimes|string',
            'name_ar'    => 'sometimes|string',
            'parent_id'  => 'nullable|integer|exists:categories,id',
            'sort_order' => 'integer',
            'is_active'  => 'boolean',
            'image'      => 'nullable|image|max:2048',
        ]);

        if ($request->hasFile('image')) {
            $data['image'] = Storage::disk('s3')->url($request->file('image')->store('categories', 's3'));
        }

        $category->update($data);

        return $this->success(new CategoryResource($category), 'Category updated');
    }

    public function destroyCategory(int $id): JsonResponse
    {
        Category::findOrFail($id)->delete();
        return $this->success(null, 'Category deleted');
    }

    // ─── Products ─────────────────────────────────────────────

    public function showProduct(int $id): JsonResponse
    {
        $product = Product::withTrashed()->with(['category', 'options.items'])->findOrFail($id);
        return $this->success(new ProductResource($product));
    }

    public function indexProducts(Request $request): JsonResponse
    {
        $products = Product::withTrashed()
            ->with('category')
            ->when($request->category_id, fn($q) => $q->where('category_id', $request->category_id))
            ->when($request->search, fn($q) => $q->where('name_en', 'like', "%{$request->search}%")
                ->orWhere('name_ar', 'like', "%{$request->search}%"))
            ->latest()
            ->paginate(20);

        return $this->paginated($products, ProductResource::collection($products));
    }

    public function storeProduct(Request $request): JsonResponse
    {
        $data = $request->validate([
            'category_id'              => 'required|integer|exists:categories,id',
            'name_en'                  => 'required|string',
            'name_ar'                  => 'required|string',
            'description_en'           => 'nullable|string',
            'description_ar'           => 'nullable|string',
            'price'                    => 'required|integer|min:0',
            'discount_price'           => 'nullable|integer|min:0',
            'is_available'             => 'boolean',
            'is_featured'              => 'boolean',
            'preparation_time_minutes' => 'integer|min:1',
            'calories'                 => 'nullable|integer',
            'sort_order'               => 'integer',
            'image'                    => 'nullable|image|max:5120',
        ]);

        if ($request->hasFile('image')) {
            $data['image'] = Storage::disk('s3')->url($request->file('image')->store('products', 's3'));
        }

        $product = Product::create($data);

        return $this->success(new ProductResource($product), 'Product created', 201);
    }

    public function updateProduct(Request $request, int $id): JsonResponse
    {
        $product = Product::findOrFail($id);

        $data = $request->validate([
            'category_id'              => 'sometimes|integer|exists:categories,id',
            'name_en'                  => 'sometimes|string',
            'name_ar'                  => 'sometimes|string',
            'description_en'           => 'nullable|string',
            'description_ar'           => 'nullable|string',
            'price'                    => 'sometimes|integer|min:0',
            'discount_price'           => 'nullable|integer|min:0',
            'is_available'             => 'boolean',
            'is_featured'              => 'boolean',
            'preparation_time_minutes' => 'integer|min:1',
            'calories'                 => 'nullable|integer',
            'sort_order'               => 'integer',
            'image'                    => 'nullable|image|max:5120',
        ]);

        if ($request->hasFile('image')) {
            $data['image'] = Storage::disk('s3')->url($request->file('image')->store('products', 's3'));
        }

        $product->update($data);

        return $this->success(new ProductResource($product->fresh('category')), 'Product updated');
    }

    public function destroyProduct(int $id): JsonResponse
    {
        $product = Product::withTrashed()->findOrFail($id);

        // If already soft-deleted, force delete permanently
        $product->trashed() ? $product->forceDelete() : $product->delete();

        return $this->success(null, 'Product deleted');
    }

    public function uploadImages(Request $request, int $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $request->validate(['images' => 'required|array', 'images.*' => 'image|max:5120']);

        $urls = [];
        foreach ($request->file('images') as $file) {
            $urls[] = Storage::disk('s3')->url($file->store('products', 's3'));
        }

        $existing = $product->images_json ?? [];
        $product->update(['images_json' => array_merge($existing, $urls)]);

        return $this->success(['images' => $product->fresh()->images_json], 'Images uploaded');
    }

    /**
     * POST /api/v1/admin/products/bulk-toggle
     */
    public function bulkToggle(Request $request): JsonResponse
    {
        $request->validate([
            'product_ids'  => 'required|array',
            'product_ids.*'=> 'integer',
            'is_available' => 'required|boolean',
        ]);

        Product::whereIn('id', $request->product_ids)
            ->update(['is_available' => $request->is_available]);

        return $this->success(null, 'Products updated');
    }

    /**
     * POST /api/v1/admin/products/import
     */
    public function importCsv(Request $request): JsonResponse
    {
        $request->validate(['file' => 'required|file|mimes:csv,txt|max:10240']);

        $file    = $request->file('file');
        $handle  = fopen($file->getRealPath(), 'r');
        $headers = fgetcsv($handle);
        $imported = 0;
        $errors   = [];

        while (($row = fgetcsv($handle)) !== false) {
            $data = array_combine($headers, $row);
            try {
                $category = \App\Models\Category::where('name_en', $data['category'] ?? '')->first();
                Product::updateOrCreate(
                    ['name_en' => $data['name_en']],
                    [
                        'category_id'    => $category?->id,
                        'name_ar'        => $data['name_ar'] ?? $data['name_en'],
                        'description_en' => $data['description_en'] ?? null,
                        'description_ar' => $data['description_ar'] ?? null,
                        'price'          => (int) ($data['price'] ?? 0),
                        'is_available'   => filter_var($data['is_available'] ?? true, FILTER_VALIDATE_BOOLEAN),
                    ]
                );
                $imported++;
            } catch (\Throwable $e) {
                $errors[] = $data['name_en'] ?? 'unknown';
            }
        }

        fclose($handle);

        return $this->success(['imported' => $imported, 'errors' => $errors], 'Import complete');
    }
}
