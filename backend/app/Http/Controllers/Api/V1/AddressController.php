<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UserAddress;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AddressController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        return $this->success($request->user()->addresses()->get());
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'label'         => 'required|in:home,work,other',
            'address_line1' => 'required|string',
            'address_line2' => 'nullable|string',
            'city'          => 'required|string',
            'district'      => 'nullable|string',
            'latitude'      => 'nullable|numeric',
            'longitude'     => 'nullable|numeric',
            'is_default'    => 'boolean',
        ]);

        if (!empty($data['is_default'])) {
            $request->user()->addresses()->update(['is_default' => false]);
        }

        $address = $request->user()->addresses()->create($data);

        return $this->success($address, 'Address added', 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $address = $request->user()->addresses()->findOrFail($id);

        $data = $request->validate([
            'label'         => 'sometimes|in:home,work,other',
            'address_line1' => 'sometimes|string',
            'address_line2' => 'nullable|string',
            'city'          => 'sometimes|string',
            'district'      => 'nullable|string',
            'latitude'      => 'nullable|numeric',
            'longitude'     => 'nullable|numeric',
            'is_default'    => 'boolean',
        ]);

        if (!empty($data['is_default'])) {
            $request->user()->addresses()->update(['is_default' => false]);
        }

        $address->update($data);

        return $this->success($address, 'Address updated');
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $request->user()->addresses()->findOrFail($id)->delete();

        return $this->success(null, 'Address deleted');
    }

    public function setDefault(Request $request, int $id): JsonResponse
    {
        $request->user()->addresses()->update(['is_default' => false]);
        $request->user()->addresses()->findOrFail($id)->update(['is_default' => true]);

        return $this->success(null, 'Default address updated');
    }
}
