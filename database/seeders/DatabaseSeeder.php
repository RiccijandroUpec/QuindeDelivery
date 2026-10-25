<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Category;
use App\Models\Coupon;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        User::create(['name' => 'Administrador', 'email' => 'admin@delivery.test', 'password' => 'admin123', 'role' => 'admin', 'approved_at' => now()]);
        $client = User::create(['name' => 'Cliente Demo', 'email' => 'cliente@delivery.test', 'password' => '123456', 'role' => 'cliente', 'phone' => '0991234567', 'approved_at' => now()]);
        User::create(['name' => 'Repartidor Demo', 'email' => 'repartidor@delivery.test', 'password' => '123456', 'role' => 'repartidor', 'phone' => '0987654321', 'vehicle' => 'Moto PBA-123', 'approved_at' => now()]);

        $client->addresses()->create([
            'label' => 'Casa',
            'address' => 'Av. Amazonas y Naciones Unidas',
            'reference' => 'Edificio azul, piso 3',
            'lat' => -0.1765,
            'lng' => -78.4846,
        ]);

        $categories = collect([
            ['Restaurantes', 'restaurant', '#10B981'],
            ['Pizzas', 'pizza', '#F97316'],
            ['Hamburguesas', 'burger', '#EF4444'],
            ['Cafeterías', 'coffee', '#A16207'],
            ['Farmacias', 'pharmacy', '#0EA5E9'],
            ['Supermercado', 'market', '#8B5CF6'],
            ['Postres', 'dessert', '#EC4899'],
            ['Mascotas', 'pets', '#14B8A6'],
        ])->mapWithKeys(fn ($c, $i) => [$c[1] => Category::create(['name' => $c[0], 'icon' => $c[1], 'color' => $c[2], 'sort' => $i])]);

        $businesses = [
            ['restaurant', 'Sabor Serrano', 'Comida típica ecuatoriana hecha en casa.', 1.50, 25, 40, 4.8, true, [
                'Platos fuertes' => [['Seco de pollo', 6.50, 'Con arroz, maduro y aguacate'], ['Fritada', 7.90, 'Con mote, tostado y llapingachos'], ['Churrasco', 8.50, 'Carne, huevo, arroz, papas fritas']],
                'Sopas' => [['Locro de papa', 3.50, 'Con queso y aguacate'], ['Yaguarlocro', 4.25, null]],
                'Bebidas' => [['Jugo de naranjilla', 1.75, null], ['Colada morada', 2.00, null]],
            ]],
            ['pizza', 'Pizza Volcán', 'Pizzas artesanales al horno de leña.', 1.99, 30, 45, 4.6, true, [
                'Pizzas' => [['Margarita mediana', 9.90, 'Tomate, mozzarella y albahaca'], ['Pepperoni mediana', 11.50, null], ['Hawaiana mediana', 11.00, null]],
                'Extras' => [['Pan de ajo', 3.25, null], ['Coca-Cola 1L', 1.80, null]],
            ]],
            ['burger', 'Burger Andes', 'Hamburguesas smash con papas rústicas.', 1.50, 20, 35, 4.7, false, [
                'Hamburguesas' => [['Smash clásica', 6.90, 'Doble carne, queso cheddar'], ['Bacon BBQ', 8.50, null], ['Pollo crispy', 7.25, null]],
                'Acompañantes' => [['Papas rústicas', 2.50, null], ['Aros de cebolla', 3.00, null]],
            ]],
            ['coffee', 'Café Quinche', 'Café de altura y pastelería.', 1.25, 15, 25, 4.9, false, [
                'Café' => [['Capuchino', 2.75, null], ['Latte', 2.95, null], ['Americano', 1.90, null]],
                'Panadería' => [['Croissant', 1.80, null], ['Empanada de viento', 1.50, null]],
            ]],
            ['pharmacy', 'Farmacia Salud+', 'Medicinas y cuidado personal 24/7.', 1.00, 20, 30, 4.5, false, [
                'Medicinas' => [['Paracetamol 500mg x10', 1.20, null], ['Ibuprofeno 400mg x10', 2.10, null]],
                'Cuidado personal' => [['Alcohol antiséptico 250ml', 1.75, null], ['Protector solar FPS50', 12.90, null]],
            ]],
            ['market', 'Mini Market La Esquina', 'Víveres, frutas y bebidas.', 1.50, 25, 40, 4.4, false, [
                'Víveres' => [['Arroz 2kg', 2.60, null], ['Aceite 1L', 2.95, null], ['Huevos x12', 2.40, null]],
                'Bebidas' => [['Agua 1.5L', 0.85, null], ['Cerveza six pack', 7.50, null]],
            ]],
            ['dessert', 'Dulce Colibrí', 'Postres, helados y tortas.', 1.75, 20, 35, 4.8, true, [
                'Postres' => [['Torta de chocolate (porción)', 3.50, null], ['Cheesecake de mora', 3.90, null]],
                'Helados' => [['Helado de paila', 2.50, 'Mora o naranjilla']],
            ]],
            ['pets', 'Pet Shop Huellitas', 'Alimento y accesorios para mascotas.', 2.00, 30, 50, 4.6, false, [
                'Alimento' => [['Croquetas perro 2kg', 9.80, null], ['Arena para gato 4kg', 6.50, null]],
            ]],
        ];

        foreach ($businesses as $i => [$cat, $name, $desc, $fee, $min, $max, $rating, $featured, $menu]) {
            $business = Business::create([
                'category_id' => $categories[$cat]->id,
                'name' => $name,
                'description' => $desc,
                'address' => 'Quito, Ecuador',
                'phone' => '02'.random_int(2000000, 2999999),
                'lat' => -0.18 + ($i * 0.004),
                'lng' => -78.49 + ($i * 0.003),
                'delivery_fee' => $fee,
                'time_min' => $min,
                'time_max' => $max,
                'rating' => $rating,
                'featured' => $featured,
                'bank_info' => "Banco Pichincha · Cta. ahorros 22{$i}0457893 · {$name}",
            ]);

            foreach ($menu as $section => $products) {
                foreach ($products as [$pName, $price, $pDesc]) {
                    $business->products()->create([
                        'section' => $section,
                        'name' => $pName,
                        'price' => $price,
                        'description' => $pDesc,
                    ]);
                }
            }
        }

        Setting::put(Setting::DEFAULTS);

        Coupon::create(['code' => 'PRIMERA20', 'description' => '20% en tu primer pedido', 'type' => 'percent', 'value' => 20, 'max_discount' => 5, 'first_order_only' => true]);
        Coupon::create(['code' => 'ENVIOGRATIS', 'description' => 'Envío gratis desde $10', 'type' => 'free_delivery', 'min_order' => 10]);
        Coupon::create(['code' => 'COLIBRI2', 'description' => '$2 de descuento', 'type' => 'fixed', 'value' => 2, 'min_order' => 8, 'max_uses' => 100]);

        User::create([
            'name' => 'Sabor Serrano', 'email' => 'negocio@delivery.test', 'password' => '123456',
            'role' => 'negocio', 'approved_at' => now(), 'business_id' => Business::where('name', 'Sabor Serrano')->value('id'),
        ]);
    }
}
