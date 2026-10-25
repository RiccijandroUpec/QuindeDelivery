<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Índices para las consultas más frecuentes cuando haya miles de pedidos.
        Schema::table('orders', function (Blueprint $table) {
            $table->index(['status', 'created_at']);
            $table->index(['business_id', 'status']);
            $table->index(['driver_id', 'status']);
            $table->index(['user_id', 'created_at']);
            $table->string('coupon_code')->nullable()->after('delivery_fee');
            $table->decimal('discount', 8, 2)->default(0)->after('coupon_code');
        });

        Schema::table('businesses', function (Blueprint $table) {
            $table->decimal('commission_rate', 5, 2)->default(10)->after('delivery_fee'); // % que cobra la plataforma
            $table->time('opens_at')->nullable()->after('is_open');
            $table->time('closes_at')->nullable()->after('opens_at');
        });

        Schema::create('coupons', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('description')->nullable();
            $table->string('type')->default('percent'); // percent, fixed, free_delivery
            $table->decimal('value', 8, 2)->default(0);
            $table->decimal('max_discount', 8, 2)->nullable();
            $table->decimal('min_order', 8, 2)->default(0);
            $table->foreignId('business_id')->nullable()->constrained()->cascadeOnDelete(); // null = todos los negocios
            $table->boolean('first_order_only')->default(false);
            $table->unsignedInteger('max_uses')->nullable();
            $table->unsignedInteger('uses')->default(0);
            $table->timestamp('expires_at')->nullable();
            $table->boolean('active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coupons');
        Schema::table('businesses', function (Blueprint $table) {
            $table->dropColumn(['commission_rate', 'opens_at', 'closes_at']);
        });
        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex(['status', 'created_at']);
            $table->dropIndex(['business_id', 'status']);
            $table->dropIndex(['driver_id', 'status']);
            $table->dropIndex(['user_id', 'created_at']);
            $table->dropColumn(['coupon_code', 'discount']);
        });
    }
};
