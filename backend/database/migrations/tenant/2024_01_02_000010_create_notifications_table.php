<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('cascade');
            $table->string('title_en');
            $table->string('title_ar');
            $table->text('body_en');
            $table->text('body_ar');
            $table->string('type')->default('general');
            $table->json('data_json')->nullable();
            $table->boolean('is_read')->default(false);
            $table->enum('sent_via', ['fcm', 'in_app', 'both'])->default('both');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
