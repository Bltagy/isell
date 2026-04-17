<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('address_id')->nullable()->constrained('user_addresses')->onDelete('set null');
            $table->enum('status', [
                'pending', 'confirmed', 'preparing',
                'ready', 'ready_for_pickup', 'out_for_delivery',
                'delivered', 'cancelled', 'refunded',
            ])->default('pending');
            $table->enum('payment_status', ['pending', 'paid', 'failed', 'refunded'])->default('pending');
            $table->enum('payment_method', ['kashier', 'cash'])->default('cash');
            $table->string('kashier_order_id')->nullable();
            $table->unsignedInteger('subtotal')->default(0);
            $table->unsignedInteger('delivery_fee')->default(0);
            $table->unsignedInteger('discount')->default(0);
            $table->unsignedInteger('tax')->default(0);
            $table->unsignedInteger('total')->default(0);
            $table->text('notes')->nullable();
            $table->unsignedInteger('estimated_delivery_minutes')->nullable();
            $table->foreignId('driver_id')->nullable()->constrained('users')->onDelete('set null');
            $table->softDeletes();
            $table->timestamps();
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->foreignId('product_id')->nullable()->constrained()->onDelete('set null');
            $table->string('product_name_snapshot');
            $table->unsignedInteger('quantity')->default(1);
            $table->unsignedInteger('unit_price');
            $table->json('options_snapshot')->nullable();
            $table->unsignedInteger('subtotal');
            $table->timestamps();
        });

        Schema::create('order_status_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->string('status');
            $table->text('note')->nullable();
            $table->foreignId('changed_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_status_histories');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
    }
};
