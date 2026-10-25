<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Configuración de la plataforma editable desde el admin.
        Schema::create('settings', function (Blueprint $table) {
            $table->string('key')->primary();
            $table->text('value')->nullable();
            $table->timestamps();
        });

        // Cada pedido guarda cómo se repartió el dinero en el momento de crearse,
        // así cambiar la configuración no altera el historial.
        Schema::table('orders', function (Blueprint $table) {
            $table->decimal('service_fee', 8, 2)->default(0)->after('delivery_fee');
            $table->decimal('commission', 8, 2)->default(0)->after('discount');
            $table->decimal('driver_earning', 8, 2)->default(0)->after('commission');
        });

        // Pedidos anteriores: el repartidor se llevaba todo el envío y la comisión era la del negocio.
        DB::table('orders')->update(['driver_earning' => DB::raw('delivery_fee')]);
        foreach (DB::table('businesses')->get(['id', 'commission_rate']) as $b) {
            DB::table('orders')->where('business_id', $b->id)
                ->update(['commission' => DB::raw('ROUND(subtotal * '.((float) $b->commission_rate).' / 100, 2)')]);
        }
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['service_fee', 'commission', 'driver_earning']);
        });
        Schema::dropIfExists('settings');
    }
};
