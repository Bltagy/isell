<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\BannerResource;
use App\Models\Banner;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AdminBannerController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        return $this->success(BannerResource::collection(Banner::orderBy('sort_order')->get()));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title_en'   => 'required|string',
            'title_ar'   => 'required|string',
            'link_type'  => 'nullable|in:category,product,offer,url',
            'link_value' => 'nullable|string',
            'sort_order' => 'integer',
            'start_date' => 'nullable|date',
            'end_date'   => 'nullable|date',
            'is_active'  => 'boolean',
            'image'      => 'required|image|max:5120',
        ]);

        $data['image'] = Storage::disk('s3')->url($request->file('image')->store('banners', 's3'));

        $banner = Banner::create($data);

        return $this->success(new BannerResource($banner), 'Banner created', 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $banner = Banner::withTrashed()->findOrFail($id);

        $data = $request->validate([
            'title_en'   => 'sometimes|string',
            'title_ar'   => 'sometimes|string',
            'link_type'  => 'nullable|in:category,product,offer,url',
            'link_value' => 'nullable|string',
            'sort_order' => 'integer',
            'start_date' => 'nullable|date',
            'end_date'   => 'nullable|date',
            'is_active'  => 'boolean',
            'image'      => 'nullable|image|max:5120',
        ]);

        if ($request->hasFile('image')) {
            $data['image'] = Storage::disk('s3')->url($request->file('image')->store('banners', 's3'));
        }

        $banner->update($data);

        return $this->success(new BannerResource($banner), 'Banner updated');
    }

    public function destroy(int $id): JsonResponse
    {
        Banner::findOrFail($id)->delete();
        return $this->success(null, 'Banner deleted');
    }
}
