<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Los repartidores necesitan aprobación del admin antes de trabajar.
        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('approved_at')->nullable()->after('active');
        });
        DB::table('users')->update(['approved_at' => now()]);

        Schema::table('businesses', function (Blueprint $table) {
            $table->text('bank_info')->nullable()->after('phone'); // datos para transferencias
            $table->unsignedInteger('rating_count')->default(0)->after('rating');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->string('transfer_proof')->nullable()->after('cash_amount');
            $table->unsignedTinyInteger('rating')->nullable()->after('cancel_reason');
            $table->string('rating_comment')->nullable()->after('rating');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['transfer_proof', 'rating', 'rating_comment']);
        });
        Schema::table('businesses', function (Blueprint $table) {
            $table->dropColumn(['bank_info', 'rating_count']);
        });
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('approved_at');
        });
    }
};
