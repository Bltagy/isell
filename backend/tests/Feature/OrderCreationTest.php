<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Offer;
use App\Models\Order;
use App\Models\Product;
use App\Models\TenantSetting;
use App\Models\User;
use App\Models\UserAddress;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderCreationTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;
    private UserAddress $address;
    private Product $product;

    protected function setUp(): void
    {
        parent::setUp();

        $this->customer = User::factory()->create(['role' => 'Customer', 'is_active' => true]);
        $this->address  = UserAddress::create([
            'user_id'       => $this->customer->id,
            'label'         => 'home',
            'address_line1' => '123 Test St',
            'city'          => 'Cairo',
            'is_default'    => true,
        ]);

        $category      = Category::create(['name_en' => 'Test', 'name_ar' => 'اختبار', 'is_active' => true]);
        $this->product = Product::create([
            'category_id'  => $category->id,
            'name_en'      => 'Test Burger',
            'name_ar'      => 'برجر اختبار',
            'price'        => 10000, // 100 EGP
            'is_available' => true,
        ]);

        TenantSetting::insert([
            ['key' => 'delivery_fee_egp',     'value' => '2000', 'type' => 'string'],
            ['key' => 'tax_percentage',        'value' => '14',   'type' => 'string'],
            ['key' => 'min_order_amount_egp',  'value' => '5000', 'type' => 'string'],
        ]);
    }

    public function test_order_calculates_correct_totals(): void
    {
        $response = $this->actingAs($this->customer)
            ->postJson('/api/v1/orders', [
                'address_id'     => $this->address->id,
                'payment_method' => 'cash',
                'items'          => [['product_id' => $this->product->id, 'quantity' => 2]],
            ]);

        $response->assertStatus(201);

        $order = Order::latest()->first();
        $this->assertEquals(20000, $order->subtotal);   // 2 × 10000
        $this->assertEquals(2000,  $order->delivery_fee);
        $this->assertEquals(2800,  $order->tax);        // 14% of 20000
        $this->assertEquals(24800, $order->total);
    }

    public function test_order_with_percentage_offer_applies_discount(): void
    {
        Offer::create([
            'code'             => 'SAVE20',
            'type'             => 'percentage',
            'value'            => 20,
            'min_order_amount' => 0,
            'applicable_to'    => 'all',
            'is_active'        => true,
            'start_date'       => now()->subDay(),
            'end_date'         => now()->addDay(),
        ]);

        $response = $this->actingAs($this->customer)
            ->postJson('/api/v1/orders', [
                'address_id'     => $this->address->id,
                'payment_method' => 'cash',
                'offer_code'     => 'SAVE20',
                'items'          => [['product_id' => $this->product->id, 'quantity' => 1]],
            ]);

        $response->assertStatus(201);

        $order = Order::latest()->first();
        $this->assertEquals(2000, $order->discount); // 20% of 10000
    }

    public function test_order_below_min_amount_returns_422(): void
    {
        // Product price 10000, min order 5000 — but after tax+delivery total should be fine
        // Set min to 50000 to force failure
        TenantSetting::where('key', 'min_order_amount_egp')->update(['value' => '50000']);

        $this->actingAs($this->customer)
            ->postJson('/api/v1/orders', [
                'address_id'     => $this->address->id,
                'payment_method' => 'cash',
                'items'          => [['product_id' => $this->product->id, 'quantity' => 1]],
            ])
            ->assertStatus(422);
    }

    public function test_order_with_unavailable_product_returns_404(): void
    {
        $this->product->update(['is_available' => false]);

        $this->actingAs($this->customer)
            ->postJson('/api/v1/orders', [
                'address_id'     => $this->address->id,
                'payment_method' => 'cash',
                'items'          => [['product_id' => $this->product->id, 'quantity' => 1]],
            ])
            ->assertStatus(404);
    }
}
