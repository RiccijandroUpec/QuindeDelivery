<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Order;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeliveryFlowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    private function placeOrder(): Order
    {
        $client = User::where('role', 'cliente')->first();
        $business = Business::with('products')->first();

        $this->actingAs($client)->postJson('/api/orders', [
            'business_id' => $business->id,
            'address' => 'Av. Amazonas',
            'lat' => -0.17,
            'lng' => -78.48,
            'payment_method' => 'efectivo',
            'items' => [['product_id' => $business->products[0]->id, 'quantity' => 2]],
        ])->assertCreated()->assertJsonPath('status', 'pendiente');

        return Order::latest('id')->first();
    }

    public function test_admin_panel_pages_render(): void
    {
        $admin = User::where('role', 'admin')->first();
        $order = Order::create([
            'user_id' => User::where('role', 'cliente')->value('id'),
            'business_id' => 1,
            'address' => 'Av. Amazonas',
            'lat' => -0.17,
            'lng' => -78.48,
            'subtotal' => 10,
            'delivery_fee' => 1.5,
            'total' => 11.5,
        ]);
        $order->items()->create(['name' => 'Seco de pollo', 'price' => 5, 'quantity' => 2, 'subtotal' => 10]);

        foreach ([
            '/admin',
            '/admin/orders',
            "/admin/orders/{$order->id}",
            "/admin/orders/{$order->id}/edit",
            '/admin/businesses',
            '/admin/businesses/1/edit',
            '/admin/businesses/create',
            '/admin/categories',
            '/admin/products',
            '/admin/products/create',
            '/admin/users',
            '/admin/users/create',
        ] as $url) {
            $this->actingAs($admin)->get($url)->assertOk();
        }
    }

    public function test_non_admin_cannot_enter_panel(): void
    {
        $this->actingAs(User::where('role', 'cliente')->first())->get('/admin')->assertForbidden();
    }

    public function test_order_prices_come_from_database(): void
    {
        $order = $this->placeOrder();
        $item = $order->items()->first();

        $this->assertEquals($item->product->price * 2, $item->subtotal);
        $this->assertEquals($order->subtotal + $order->business->delivery_fee + $order->service_fee, $order->total);
    }

    public function test_driver_full_flow(): void
    {
        $order = $this->placeOrder();
        $driver = User::where('role', 'repartidor')->first();

        // Aún pendiente: no visible para repartidores.
        $this->actingAs($driver)->getJson('/api/driver/orders/available')->assertJsonCount(0);

        $order->update(['status' => 'listo']);
        $this->actingAs($driver)->getJson('/api/driver/orders/available')->assertJsonCount(1);
        $this->actingAs($driver)->postJson("/api/driver/orders/{$order->id}/accept")->assertOk();

        // Otro repartidor ya no puede tomarlo.
        $other = User::create(['name' => 'Otro', 'email' => 'otro@test.com', 'password' => 'x', 'role' => 'repartidor', 'approved_at' => now()]);
        $this->actingAs($other)->postJson("/api/driver/orders/{$order->id}/accept")->assertUnprocessable();

        // No se puede saltar directo a entregado.
        $this->actingAs($driver)->postJson("/api/driver/orders/{$order->id}/status", ['status' => 'entregado'])->assertUnprocessable();

        $this->actingAs($driver)->postJson('/api/driver/location', ['lat' => -0.171, 'lng' => -78.481])->assertJson(['updated' => 1]);
        $this->actingAs($driver)->postJson("/api/driver/orders/{$order->id}/status", ['status' => 'en_camino'])->assertJsonPath('status', 'en_camino');
        $this->actingAs($driver)->postJson("/api/driver/orders/{$order->id}/status", ['status' => 'entregado'])->assertJsonPath('status', 'entregado');

        $this->assertNotNull($order->fresh()->delivered_at);
    }

    public function test_roles_are_enforced(): void
    {
        $client = User::where('role', 'cliente')->first();
        $driver = User::where('role', 'repartidor')->first();

        $this->actingAs($client)->getJson('/api/driver/orders/available')->assertForbidden();
        $this->actingAs($driver)->getJson('/api/orders')->assertForbidden();
    }

    public function test_client_cannot_see_other_clients_orders(): void
    {
        $order = $this->placeOrder();
        $intruder = User::create(['name' => 'X', 'email' => 'x@test.com', 'password' => 'x', 'role' => 'cliente']);

        $this->actingAs($intruder)->getJson("/api/orders/{$order->id}")->assertForbidden();
    }

    public function test_business_manages_its_orders(): void
    {
        $order = $this->placeOrder();
        $owner = User::where('role', 'negocio')->first();
        $this->assertEquals($order->business_id, $owner->business_id);

        $this->actingAs($owner)->getJson('/api/business/orders?active=1')->assertJsonCount(1);

        // No puede saltar directo a listo desde pendiente.
        $this->actingAs($owner)->postJson("/api/business/orders/{$order->id}/status", ['status' => 'listo'])->assertUnprocessable();

        foreach (['aceptado', 'preparando', 'listo'] as $status) {
            $this->actingAs($owner)->postJson("/api/business/orders/{$order->id}/status", ['status' => $status])
                ->assertJsonPath('status', $status);
        }

        $driver = User::where('role', 'repartidor')->first();
        $this->actingAs($driver)->getJson('/api/driver/orders/available')->assertJsonCount(1);
    }

    public function test_business_rejects_with_reason(): void
    {
        $order = $this->placeOrder();
        $owner = User::where('role', 'negocio')->first();

        $this->actingAs($owner)->postJson("/api/business/orders/{$order->id}/status", ['status' => 'cancelado'])->assertUnprocessable();
        $this->actingAs($owner)->postJson("/api/business/orders/{$order->id}/status", ['status' => 'cancelado', 'reason' => 'Sin stock'])
            ->assertJsonPath('status', 'cancelado')
            ->assertJsonPath('cancel_reason', 'Sin stock');

        $client = User::where('role', 'cliente')->first();
        $this->actingAs($client)->getJson("/api/orders/{$order->id}")->assertJsonPath('cancel_reason', 'Sin stock');
    }

    public function test_business_cannot_touch_other_business_orders(): void
    {
        $order = $this->placeOrder();
        $other = User::create([
            'name' => 'Otro negocio', 'email' => 'otro-negocio@test.com', 'password' => 'x',
            'role' => 'negocio', 'business_id' => Business::where('id', '!=', $order->business_id)->value('id'),
        ]);

        $this->actingAs($other)->getJson("/api/business/orders/{$order->id}")->assertForbidden();
        $this->actingAs($other)->postJson("/api/business/orders/{$order->id}/status", ['status' => 'aceptado'])->assertForbidden();
        $this->actingAs(User::where('role', 'cliente')->first())->getJson('/api/business/orders')->assertForbidden();
    }

    public function test_business_toggles_open(): void
    {
        $owner = User::where('role', 'negocio')->first();

        $this->actingAs($owner)->putJson('/api/business/open', ['is_open' => false])->assertJsonPath('is_open', false);
        $this->assertFalse($owner->business->fresh()->is_open);
    }
}
