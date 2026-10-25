<?php

namespace Tests\Feature;

use App\Models\Business;
use App\Models\Order;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProductionFeaturesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    private function placeOrder(string $payment = 'efectivo'): Order
    {
        $business = Business::with('products')->first();

        $this->actingAs(User::where('role', 'cliente')->first())->postJson('/api/orders', [
            'business_id' => $business->id,
            'address' => 'Av. Amazonas',
            'lat' => -0.17,
            'lng' => -78.48,
            'payment_method' => $payment,
            'items' => [['product_id' => $business->products[0]->id, 'quantity' => 1]],
        ])->assertCreated();

        return Order::latest('id')->first();
    }

    public function test_new_drivers_wait_for_approval(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Nuevo', 'email' => 'nuevo@test.com', 'password' => '123456', 'role' => 'repartidor',
        ])->assertCreated()->assertJsonPath('pending', true)->assertJsonMissingPath('token');

        $this->postJson('/api/login', ['email' => 'nuevo@test.com', 'password' => '123456'])->assertUnprocessable();

        $driver = User::where('email', 'nuevo@test.com')->first();
        $this->actingAs($driver)->getJson('/api/driver/orders/available')->assertForbidden();

        $driver->update(['approved_at' => now()]);
        $this->postJson('/api/login', ['email' => 'nuevo@test.com', 'password' => '123456'])->assertOk();
    }

    public function test_clients_register_without_approval(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Cliente', 'email' => 'c@test.com', 'password' => '123456',
        ])->assertCreated()->assertJsonStructure(['token']);
    }

    public function test_login_is_rate_limited(): void
    {
        for ($i = 0; $i < 10; $i++) {
            $this->postJson('/api/login', ['email' => 'cliente@delivery.test', 'password' => 'mal']);
        }
        $this->postJson('/api/login', ['email' => 'cliente@delivery.test', 'password' => 'mal'])->assertStatus(429);
    }

    public function test_driver_picks_up_only_when_ready(): void
    {
        $order = $this->placeOrder();
        $order->update(['status' => 'preparando']);
        $driver = User::where('role', 'repartidor')->first();

        $this->actingAs($driver)->postJson("/api/driver/orders/{$order->id}/accept")->assertOk();
        $this->actingAs($driver)->postJson("/api/driver/orders/{$order->id}/status", ['status' => 'en_camino'])->assertUnprocessable();

        $order->update(['status' => 'listo']);
        $this->actingAs($driver)->postJson("/api/driver/orders/{$order->id}/status", ['status' => 'en_camino'])->assertOk();
    }

    public function test_stale_pending_orders_expire(): void
    {
        $old = $this->placeOrder();
        $old->forceFill(['created_at' => now()->subMinutes(Order::PENDING_TIMEOUT + 1)])->save();
        $fresh = $this->placeOrder();

        $this->artisan('orders:expire')->assertSuccessful();

        $this->assertEquals('cancelado', $old->fresh()->status);
        $this->assertNotNull($old->fresh()->cancel_reason);
        $this->assertEquals('pendiente', $fresh->fresh()->status);
    }

    public function test_client_uploads_transfer_proof(): void
    {
        Storage::fake('public');
        $order = $this->placeOrder('transferencia');
        $client = User::where('role', 'cliente')->first();

        $res = $this->actingAs($client)->post("/api/orders/{$order->id}/proof", [
            'proof' => UploadedFile::fake()->image('comprobante.jpg'),
        ], ['Accept' => 'application/json'])->assertOk();

        $this->assertNotNull($res->json('transfer_proof_url'));
        Storage::disk('public')->assertExists($order->fresh()->transfer_proof);

        $owner = User::where('role', 'negocio')->first();
        $this->actingAs($owner)->getJson("/api/business/orders/{$order->id}")->assertJsonPath('transfer_proof_url', $res->json('transfer_proof_url'));
    }

    public function test_cash_orders_reject_proof(): void
    {
        Storage::fake('public');
        $order = $this->placeOrder();

        $this->actingAs(User::where('role', 'cliente')->first())->post("/api/orders/{$order->id}/proof", [
            'proof' => UploadedFile::fake()->image('x.jpg'),
        ], ['Accept' => 'application/json'])->assertUnprocessable();
    }

    public function test_client_rates_delivered_order_once(): void
    {
        $order = $this->placeOrder();
        $client = User::where('role', 'cliente')->first();

        $this->actingAs($client)->postJson("/api/orders/{$order->id}/rate", ['rating' => 5])->assertUnprocessable();

        $order->update(['status' => 'entregado']);
        $this->actingAs($client)->postJson("/api/orders/{$order->id}/rate", ['rating' => 4, 'comment' => 'Rico'])
            ->assertOk()->assertJsonPath('rating', 4);
        $this->actingAs($client)->postJson("/api/orders/{$order->id}/rate", ['rating' => 1])->assertUnprocessable();

        $business = $order->business->fresh();
        $this->assertEquals(4.0, $business->rating);
        $this->assertEquals(1, $business->rating_count);
    }

    public function test_business_manages_its_menu(): void
    {
        $owner = User::where('role', 'negocio')->first();
        $product = $owner->business->products()->first();

        $this->actingAs($owner)->getJson('/api/business/products')->assertOk()->assertJsonCount($owner->business->products()->count());
        $this->actingAs($owner)->patchJson("/api/business/products/{$product->id}", ['available' => false, 'price' => 9.99])
            ->assertJsonPath('available', false);
        $this->assertEquals(9.99, (float) $product->fresh()->price);

        // El producto agotado ya no aparece en el menú del cliente.
        $menu = $this->getJson("/api/businesses/{$owner->business_id}")->json('products.*.id');
        $this->assertNotContains($product->id, $menu);

        $foreign = Business::where('id', '!=', $owner->business_id)->first()->products()->first();
        $this->actingAs($owner)->patchJson("/api/business/products/{$foreign->id}", ['available' => false])->assertForbidden();
    }
}
