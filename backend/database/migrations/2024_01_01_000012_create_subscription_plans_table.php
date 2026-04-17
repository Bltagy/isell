<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->unsignedInteger('price_monthly')->default(0); // in piastres
            $table->unsignedInteger('price_yearly')->default(0);  // in piastres
            $table->unsignedInteger('max_products')->default(100);
            $table->unsignedInteger('max_orders_per_month')->default(1000);
            $table->unsignedInteger('max_branches')->default(1);
            $table->json('features_json')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('created_at')->nullable();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_plans');
    }
};
