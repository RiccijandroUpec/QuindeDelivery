# Colibrí Delivery – API + Panel admin

Laravel 12 + Filament 5 + Sanctum, MySQL (XAMPP, BD `delivery`).
App Flutter que la consume: `C:\Users\richa\StudioProjects\Delivery`.

## Comandos
- Server: `php artisan serve --host=0.0.0.0 --port=8000`
- Tareas programadas: `php artisan schedule:work` (cancela pedidos `pendiente` tras `Order::PENDING_TIMEOUT` min con `orders:expire`, en `routes/console.php`)
- Panel admin: http://localhost:8000/admin
- BD: `php artisan migrate:fresh --seed` (crea cuentas de prueba)
- Tests: `php artisan test` (`DeliveryFlowTest` flujo completo, `ProductionFeaturesTest` aprobación, throttle, vencimiento, comprobantes, calificaciones, menú)
- Formato: `vendor/bin/pint`

## Estructura
- `routes/api.php` – todas las rutas de la API (prefijo `/api`)
- `app/Http/Controllers/Api/` – Auth, Catalog, Address, Order (cliente), Driver (repartidor), Business (negocio)
- `app/Http/Middleware/EnsureRole.php` – alias `role:` (registrado en `bootstrap/app.php`)
- `app/Models/` – User, Business, Category, Product, Address, Order, OrderItem
- `app/Filament/Resources/` – Businesses, Categories, Products, Orders, Users
- `database/seeders/DatabaseSeeder.php` – datos y cuentas de prueba

## API
- Públicas: `POST /register`, `POST /login` (throttle 10/min), `GET /categories`, `GET /businesses`, `GET /businesses/{id}`
- `auth:sanctum`: `GET|PUT /me`, `POST /logout`
- `role:cliente`: CRUD `/addresses`, `GET|POST /orders`, `GET /orders/{id}`, `POST /orders/{id}/cancel`,
  `POST /orders/{id}/proof` (multipart `proof`, solo transferencia), `POST /orders/{id}/rate` (1-5, solo entregado, una vez)
- `role:repartidor` (prefijo `/driver`): `GET /orders/available`, `GET /orders`, `GET /orders/{id}`,
  `POST /orders/{id}/accept`, `POST /orders/{id}/status`, `POST /location`
- `role:negocio` (prefijo `/business`): `GET /`, `PUT /open`, `GET /orders?active=1`, `GET /orders/{id}`,
  `POST /orders/{id}/status` (aceptado | preparando | listo | cancelado + `reason`), `GET /products`, `PATCH /products/{id}` (available, price)

## Reglas de negocio
- Roles de usuario: `admin`, `cliente`, `repartidor`, `negocio` (usa `users.business_id`; login/me incluyen `business`).
- Estados del pedido: `pendiente` → (negocio o admin) `aceptado` → `preparando` → `listo` → (repartidor) `en_camino` → `entregado`.
- Repartidores registrados desde la app quedan con `approved_at` null hasta que el admin los aprueba (Usuarios → Aprobar); `EnsureRole` los bloquea.
- El repartidor solo pasa a `en_camino` desde `listo`.
- Pago: efectivo (`cash_amount` para el vuelto) o transferencia (datos en `businesses.bank_info`, comprobante en `orders.transfer_proof`, disco public).
- Calificación: `orders.rating` → `Business::refreshRating()` recalcula `rating` y `rating_count`.
- Al cambiar la API, actualizar también `lib/api.dart` y `lib/models.dart` de la app.

## Cuentas de prueba
admin@delivery.test / admin123 · cliente@delivery.test / 123456 · repartidor@delivery.test / 123456 · negocio@delivery.test / 123456
