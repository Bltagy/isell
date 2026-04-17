<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\BannerResource;
use App\Http\Resources\CategoryResource;
use App\Http\Resources\OfferResource;
use App\Http\Resources\ProductResource;
use App\Models\Banner;
use App\Models\Category;
use App\Models\Offer;
use App\Models\Product;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class HomeController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/home — cached 2 minutes.
     */
    public function index(): JsonResponse
    {
        $data = Cache::remember('home_data', 120, function () {
            return [
                'banners'          => BannerResource::collection(Banner::active()->orderBy('sort_order')->get()),
                'featured_products' => ProductResource::collection(
                    Product::available()->featured()->with('category')->limit(10)->get()
                ),
                'categories'       => CategoryResource::collection(
                    Category::active()->topLevel()->with('children')->orderBy('sort_order')->get()
                ),
                'active_offers'    => OfferResource::collection(Offer::active()->get()),
            ];
        });

        return $this->success($data);
    }
}
