<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Usuarios con rol "negocio" administran los pedidos de su negocio.
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('business_id')->nullable()->after('role')->constrained()->nullOnDelete();
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->string('cancel_reason')->nullable()->after('notes');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('cancel_reason');
        });
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('business_id');
        });
    }
};
