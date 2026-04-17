<?php

namespace App\Http\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

class CreateOrderRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'items'                    => 'required|array|min:1',
            'items.*.product_id'       => 'required|integer|exists:products,id',
            'items.*.quantity'         => 'required|integer|min:1|max:99',
            'items.*.options'          => 'nullable|array',
            'items.*.options.*.option_id' => 'required|integer',
            'items.*.options.*.item_ids'  => 'required|array',
            'address_id'               => 'nullable|integer|exists:user_addresses,id',
            'payment_method'           => 'required|in:kashier,cash',
            'offer_code'               => 'nullable|string',
            'notes'                    => 'nullable|string|max:500',
        ];
    }
}
