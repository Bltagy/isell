<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                 => $this->id,
            'name'               => $this->name,
            'email'              => $this->email,
            'phone'              => $this->phone,
            'avatar'             => $this->avatar,
            'role'               => $this->role,
            'is_active'          => $this->is_active,
            'preferred_language' => $this->preferred_language,
            'email_verified'     => !is_null($this->email_verified_at),
            'phone_verified'     => !is_null($this->phone_verified_at),
            'profile'            => $this->whenLoaded('profile', fn() => [
                'date_of_birth'  => $this->profile?->date_of_birth,
                'gender'         => $this->profile?->gender,
                'loyalty_points' => $this->profile?->loyalty_points ?? 0,
            ]),
            'created_at'         => $this->created_at?->toISOString(),
            'joined_at'          => $this->created_at?->toISOString(),
            'orders_count'       => $this->when(isset($this->orders_count), $this->orders_count, fn() => 0),
            'total_spent'        => $this->when(isset($this->total_spent), (int)($this->total_spent ?? 0), 0),

            // Detail view — only present when relations are loaded
            'orders' => $this->whenLoaded('orders', fn() => $this->orders->map(fn($o) => [
                'id'           => $o->id,
                'order_number' => (string) $o->id,
                'total'        => (int) $o->total,
                'status'       => $o->status,
                'created_at'   => $o->created_at?->toISOString(),
            ])),

            'addresses' => $this->whenLoaded('addresses', fn() => $this->addresses->map(fn($a) => [
                'id'      => $a->id,
                'label'   => $a->label,
                'address' => implode(', ', array_filter([
                    $a->address_line1,
                    $a->address_line2,
                    $a->district,
                    $a->city,
                ])),
            ])),
        ];
    }
}
