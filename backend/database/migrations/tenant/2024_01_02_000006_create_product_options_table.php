<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_options', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->onDelete('cascade');
            $table->string('name_en');
            $table->string('name_ar');
            $table->enum('type', ['single', 'multiple'])->default('single');
            $table->boolean('is_required')->default(false);
            $table->unsignedInteger('max_selections')->default(1);
            $table->timestamps();
        });

        Schema::create('product_option_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('option_id')->constrained('product_options')->onDelete('cascade');
            $table->string('name_en');
            $table->string('name_ar');
            $table->unsignedInteger('extra_price')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_option_items');
        Schema::dropIfExists('product_options');
    }
};
