<?php

namespace Tests\Feature;

use App\Filament\Pages\PlatformSettings;
use App\Filament\Settlements\PlatformRevenue;
use App\Models\Business;
use App\Models\Order;
use App\Models\Setting;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class PlatformRevenueTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    private function placeOrder(array $extra = []): Order
    {
        $business = Business::with('products')->first();
        $res = $this->actingAs(User::where('role', 'cliente')->first())->postJson('/api/orders', [
            'business_id' => $business->id,
            'address' => 'Av. Amazonas',
            'lat' => -0.17,
            'lng' => -78.48,
            'payment_method' => 'efectivo',
            'items' => [['product_id' => $business->products[0]->id, 'quantity' => 2]],
            ...$extra,
        ])->assertCreated();

        return Order::find($res->json('id'));
    }

    public function test_order_splits_money_with_current_settings(): void
    {
        Setting::put(['service_fee' => 0.50, 'driver_share' => 80]);
        $business = Business::first();
        $business->update(['commission_rate' => 15, 'delivery_fee' => 2]);

        $order = $this->placeOrder();

        $this->assertEquals(0.50, $order->service_fee);
        $this->assertEquals(round($order->subtotal * .15, 2), $order->commission);
        $this->assertEquals(1.60, $order->driver_earning);
        $this->assertEquals(round($order->subtotal + 2 + 0.50, 2), $order->total);
    }

    public function test_changing_settings_does_not_touch_old_orders(): void
    {
        Setting::put(['service_fee' => 0.25, 'driver_share' => 100]);
        $old = $this->placeOrder();

        Setting::put(['service_fee' => 1, 'driver_share' => 50]);
        $new = $this->placeOrder();

        $this->assertEquals(0.25, $old->fresh()->service_fee);
        $this->assertEquals($old->delivery_fee, $old->fresh()->driver_earning);
        $this->assertEquals(1, $new->service_fee);
        $this->assertEquals(round($new->delivery_fee / 2, 2), $new->driver_earning);
    }

    public function test_public_settings_endpoint(): void
    {
        Setting::put(['service_fee' => 0.35]);
        $this->getJson('/api/settings')->assertOk()->assertExactJson(['service_fee' => 0.35]);
    }

    public function test_platform_net_revenue(): void
    {
        Setting::put(['service_fee' => 0.50, 'driver_share' => 80]);
        Business::first()->update(['commission_rate' => 10, 'delivery_fee' => 2]);

        $a = $this->placeOrder();
        $b = $this->placeOrder(['coupon_code' => 'COLIBRI2']);
        Order::whereKey([$a->id, $b->id])->update(['status' => 'entregado', 'delivered_at' => now()]);

        $r = PlatformRevenue::totals(Order::where('status', 'entregado'));
        $expected = $a->commission + $b->commission + 1.0 + 0.8 - $b->discount;

        $this->assertEquals(round($expected, 2), $r['net']);
        $this->assertEquals(1.0, $r['service']);
        $this->assertEquals(0.8, round($r['delivery'], 2));
    }

    public function test_admin_settings_page_saves(): void
    {
        $admin = User::where('role', 'admin')->first();
        $this->actingAs($admin, 'web')->get('/admin/tarifas')->assertOk();

        Livewire::actingAs($admin)
            ->test(PlatformSettings::class)
            ->set('data.service_fee', 0.4)
            ->set('data.driver_share', 75)
            ->call('save')
            ->assertHasNoErrors();

        $this->assertEquals(0.4, Setting::float('service_fee'));
        $this->assertEquals(75, Setting::float('driver_share'));
        $this->actingAs($admin, 'web')->get('/admin/liquidaciones')->assertOk();
    }
}
