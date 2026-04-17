<?php

namespace Database\Seeders;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatusHistory;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;

class OrderSeeder extends Seeder
{
    public function run(): void
    {
        $customers = User::customers()->with('addresses')->get();
        $products  = Product::all();

        if ($customers->isEmpty() || $products->isEmpty()) {
            return;
        }

        // 30 orders spread across statuses and dates
        $statusPool = [
            'pending', 'pending', 'pending',
            'confirmed', 'confirmed',
            'preparing', 'preparing',
            'ready', 'ready',
            'out_for_delivery', 'out_for_delivery',
            'delivered', 'delivered', 'delivered', 'delivered', 'delivered',
            'delivered', 'delivered', 'delivered', 'delivered', 'delivered',
            'cancelled', 'cancelled', 'cancelled',
            'pending', 'confirmed', 'preparing', 'delivered', 'delivered', 'cancelled',
        ];

        foreach ($statusPool as $i => $status) {
            $customer = $customers->random();
            $address  = $customer->addresses->first();

            $selectedProducts = $products->random(rand(1, 4));
            $subtotal = 0;
            $items    = [];

            foreach ($selectedProducts as $product) {
                $qty       = rand(1, 3);
                $price     = $product->price;
                $itemTotal = $price * $qty;
                $subtotal += $itemTotal;

                $items[] = [
                    'product_id'            => $product->id,
                    'product_name_snapshot' => $product->name_en,
                    'quantity'              => $qty,
                    'unit_price'            => $price,
                    'options_snapshot'      => null,
                    'subtotal'              => $itemTotal,
                ];
            }

            $deliveryFee = 2000;
            $tax         = (int) round($subtotal * 0.14);
            $discount    = (rand(0, 3) === 0) ? rand(500, 2000) : 0; // occasional discount
            $total       = $subtotal + $deliveryFee + $tax - $discount;

            $daysAgo = match (true) {
                $i < 5  => rand(0, 1),   // recent
                $i < 15 => rand(2, 7),   // this week
                default => rand(8, 30),  // this month
            };

            $order = Order::create([
                'user_id'        => $customer->id,
                'address_id'     => $address?->id,
                'status'         => $status,
                'payment_status' => in_array($status, ['delivered', 'out_for_delivery']) ? 'paid' : 'pending',
                'payment_method' => rand(0, 1) ? 'cash' : 'kashier',
                'subtotal'       => $subtotal,
                'delivery_fee'   => $deliveryFee,
                'discount'       => $discount,
                'tax'            => $tax,
                'total'          => $total,
                'notes'          => rand(0, 3) === 0 ? 'Please ring the bell twice.' : null,
                'created_at'     => now()->subDays($daysAgo)->subMinutes(rand(0, 1440)),
            ]);

            foreach ($items as $item) {
                OrderItem::create(array_merge($item, ['order_id' => $order->id]));
            }

            // Status history
            OrderStatusHistory::create([
                'order_id'   => $order->id,
                'status'     => 'pending',
                'created_at' => $order->created_at,
            ]);

            $progressStatuses = ['confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered'];
            $minutes = 5;
            foreach ($progressStatuses as $s) {
                if ($s === $status || ($status === 'cancelled' && $s === 'confirmed')) {
                    OrderStatusHistory::create([
                        'order_id'   => $order->id,
                        'status'     => $s,
                        'created_at' => $order->created_at->addMinutes($minutes),
                    ]);
                    break;
                }
                if (in_array($s, ['confirmed', 'preparing', 'ready', 'out_for_delivery'])) {
                    $statusIndex = array_search($status, $progressStatuses);
                    $sIndex      = array_search($s, $progressStatuses);
                    if ($statusIndex !== false && $sIndex <= $statusIndex) {
                        OrderStatusHistory::create([
                            'order_id'   => $order->id,
                            'status'     => $s,
                            'created_at' => $order->created_at->addMinutes($minutes),
                        ]);
                        $minutes += rand(5, 15);
                    }
                }
            }
        }
    }
}
