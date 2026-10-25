<?php

namespace Tests\Feature;

use App\Events\DriverMoved;
use App\Events\OrderChanged;
use App\Models\Business;
use App\Models\Coupon;
use App\Models\Order;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class GrowthFeaturesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    private function client(): User
    {
        return User::where('role', 'cliente')->first();
    }

    private function order(array $extra = [], int $qty = 2): TestResponse
    {
        $business = Business::with('products')->first();

        return $this->actingAs($this->client())->postJson('/api/orders', [
            'business_id' => $business->id,
            'address' => 'Av. Amazonas',
            'lat' => -0.17,
            'lng' => -78.48,
            'payment_method' => 'efectivo',
            'items' => [['product_id' => $business->products[0]->id, 'quantity' => $qty]],
            ...$extra,
        ]);
    }

    public function test_percent_coupon_applies_with_cap_and_counts_use(): void
    {
        $res = $this->order(['coupon_code' => 'primera20'], qty: 5)->assertCreated();
        $order = Order::find($res->json('id'));

        $this->assertEquals('PRIMERA20', $order->coupon_code);
        $this->assertEquals(min($order->subtotal * .2, 5), $order->discount);
        $this->assertEquals(round($order->subtotal + $order->delivery_fee - $order->discount, 2), $order->total);
        $this->assertEquals(1, Coupon::where('code', 'PRIMERA20')->value('uses'));

        // Solo es para el primer pedido.
        $this->order(['coupon_code' => 'PRIMERA20'])->assertUnprocessable()->assertJsonValidationErrors('coupon_code');
    }

    public function test_coupon_check_endpoint(): void
    {
        $business = Business::first();
        $client = $this->client();

        $this->actingAs($client)->postJson('/api/coupons/check', ['code' => 'ENVIOGRATIS', 'business_id' => $business->id, 'subtotal' => 5])
            ->assertUnprocessable();
        $this->actingAs($client)->postJson('/api/coupons/check', ['code' => 'ENVIOGRATIS', 'business_id' => $business->id, 'subtotal' => 12])
            ->assertOk()->assertJsonPath('discount', $business->delivery_fee);
        $this->actingAs($client)->postJson('/api/coupons/check', ['code' => 'NOEXISTE', 'business_id' => $business->id, 'subtotal' => 12])
            ->assertUnprocessable();
    }

    public function test_expired_and_exhausted_coupons_are_rejected(): void
    {
        Coupon::create(['code' => 'VIEJO', 'type' => 'fixed', 'value' => 1, 'expires_at' => now()->subDay()]);
        Coupon::create(['code' => 'AGOTADO', 'type' => 'fixed', 'value' => 1, 'max_uses' => 1, 'uses' => 1]);

        $this->order(['coupon_code' => 'VIEJO'])->assertUnprocessable();
        $this->order(['coupon_code' => 'AGOTADO'])->assertUnprocessable();
    }

    public function test_coupon_use_is_claimed_atomically(): void
    {
        $coupon = Coupon::create(['code' => 'UNICO', 'type' => 'fixed', 'value' => 1, 'max_uses' => 1]);
        // Dos pedidos que validaron el cupón al mismo tiempo: solo uno lo consume.
        $this->assertTrue($coupon->claimUse());
        $this->assertFalse($coupon->claimUse());
        $this->assertEquals(1, $coupon->fresh()->uses);
    }

    public function test_short_passwords_are_rejected(): void
    {
        $this->postJson('/api/register', ['name' => 'A', 'email' => 'a@test.com', 'password' => '1234567'])
            ->assertUnprocessable()->assertJsonValidationErrors('password');
    }

    public function test_business_hours_close_the_business(): void
    {
        $this->travelTo(now(Business::TIMEZONE)->setTime(23, 30));
        $business = Business::first();
        $business->update(['opens_at' => '08:00', 'closes_at' => '22:00']);

        $this->assertFalse($business->fresh()->open_now);
        $this->order()->assertUnprocessable();

        // Horario que cruza la medianoche.
        $business->update(['opens_at' => '18:00', 'closes_at' => '02:00']);
        $this->assertTrue($business->fresh()->open_now);
    }

    public function test_business_sets_hours_from_app(): void
    {
        $owner = User::where('role', 'negocio')->first();

        $this->actingAs($owner)->putJson('/api/business/hours', ['opens_at' => '09:00', 'closes_at' => '21:30'])->assertOk();
        $this->actingAs($owner)->putJson('/api/business/hours', ['opens_at' => '09:00'])->assertUnprocessable();
        $this->actingAs($owner)->putJson('/api/business/hours', ['opens_at' => null, 'closes_at' => null])->assertOk();
        $this->assertNull($owner->business->fresh()->opens_at);
    }

    public function test_business_uploads_product_photo(): void
    {
        Storage::fake('public');
        $owner = User::where('role', 'negocio')->first();
        $product = $owner->business->products()->first();

        $res = $this->actingAs($owner)->post("/api/business/products/{$product->id}/image", [
            'image' => UploadedFile::fake()->image('plato.jpg'),
        ], ['Accept' => 'application/json'])->assertOk();

        $this->assertNotNull($res->json('image_url'));
        Storage::disk('public')->assertExists($product->fresh()->image);
    }

    public function test_transfer_proof_is_private_and_served_with_signed_link(): void
    {
        Storage::fake('local');
        $order = Order::find($this->order(['payment_method' => 'transferencia'])->json('id'));

        $res = $this->actingAs($this->client())->post("/api/orders/{$order->id}/proof", [
            'proof' => UploadedFile::fake()->image('comprobante.jpg'),
        ], ['Accept' => 'application/json'])->assertOk();

        Storage::disk('local')->assertExists($order->fresh()->transfer_proof);
        $this->assertArrayNotHasKey('transfer_proof', $res->json());

        $this->get($res->json('transfer_proof_url'))->assertOk();
        $this->get("/api/proofs/{$order->id}")->assertForbidden();
        $this->get(URL::temporarySignedRoute('orders.proof', now()->subMinute(), ['order' => $order->id]))->assertForbidden();
    }

    public function test_driver_cannot_see_client_before_accepting(): void
    {
        $order = Order::find($this->order()->json('id'));
        $order->update(['status' => 'listo']);
        $driver = User::where('role', 'repartidor')->first();

        $this->actingAs($driver)->getJson("/api/driver/orders/{$order->id}")->assertOk()->assertJsonMissingPath('user');
        $this->actingAs($driver)->postJson("/api/driver/orders/{$order->id}/accept")->assertJsonPath('user.name', $this->client()->name);
    }

    public function test_order_changes_are_broadcast(): void
    {
        Event::fake([OrderChanged::class, DriverMoved::class]);

        $order = Order::find($this->order()->json('id'));
        Event::assertDispatched(OrderChanged::class, fn ($e) => $e->order->is($order));

        $owner = User::where('role', 'negocio')->first();
        $this->actingAs($owner)->postJson("/api/business/orders/{$order->id}/status", ['status' => 'aceptado']);
        Event::assertDispatchedTimes(OrderChanged::class, 2);

        $driver = User::where('role', 'repartidor')->first();
        $this->actingAs($driver)->postJson("/api/driver/orders/{$order->id}/accept");
        $this->actingAs($driver)->postJson('/api/driver/location', ['lat' => -0.17, 'lng' => -78.48]);
        Event::assertDispatched(DriverMoved::class, fn ($e) => $e->orderId === $order->id);
    }

    public function test_channel_authorization(): void
    {
        $order = Order::find($this->order()->json('id'));
        $intruder = User::create(['name' => 'X', 'email' => 'x@test.com', 'password' => 'x', 'role' => 'cliente', 'approved_at' => now()]);
        $owner = User::where('role', 'negocio')->first();

        // En los tests el broadcaster es "null", así que se prueban directo las reglas de routes/channels.php.
        $channels = Broadcast::driver()->getChannels();
        $orderChannel = $channels['orders.{order}'];
        $businessChannel = $channels['business.{businessId}'];
        $drivers = $channels['drivers'];

        $this->assertTrue($orderChannel($this->client(), $order));
        $this->assertFalse($orderChannel($intruder, $order));
        $this->assertTrue($businessChannel($owner, $owner->business_id));
        $this->assertFalse($businessChannel($owner, $owner->business_id + 1));
        $this->assertFalse($drivers($this->client()));
        $this->assertTrue($drivers(User::where('role', 'repartidor')->first()));
    }

    public function test_admin_growth_pages_render(): void
    {
        $admin = User::where('role', 'admin')->first();
        $order = Order::find($this->order()->json('id'));
        $order->update(['status' => 'entregado', 'delivered_at' => now()]);

        foreach (['/admin', '/admin/coupons', '/admin/liquidaciones', "/admin/orders/{$order->id}"] as $url) {
            // El panel usa la sesión web; la petición anterior a la API dejó Sanctum como guard por defecto.
            $this->actingAs($admin, 'web')->get($url)->assertOk();
        }
    }
}
