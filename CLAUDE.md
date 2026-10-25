# Quinde Delivery – API + Panel admin

Laravel 12 + Filament 5 + Sanctum, MySQL (XAMPP, BD `delivery`).
App Flutter que la consume: `C:\Users\richa\StudioProjects\Delivery`.

## Comandos
- Server: `php artisan serve --host=0.0.0.0 --port=8000`
- Tiempo real: `php artisan reverb:start --host=0.0.0.0 --port=8080` (Laravel Reverb, protocolo Pusher)
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
- `database/seeders/DatabaseSeeder.php` – datos, cuentas y cupones de prueba (PRIMERA20, ENVIOGRATIS, QUINDE2)
- `app/Events/` – `OrderChanged` (canales `orders.{id}`, `business.{id}`, `drivers`) y `DriverMoved` (`orders.{id}`); se disparan desde `Order::booted()` con `rescue()` para no fallar si Reverb está apagado
- `routes/channels.php` – permisos de canales privados; auth en `POST /api/broadcasting/auth` con token Sanctum
- `app/Filament/Widgets/` – métricas del dashboard; `app/Filament/Pages/Settlements.php` + `app/Filament/Settlements/` – liquidaciones (comisiones y ganancias)

## API
- Públicas: `GET /settings` (tarifa de servicio), `POST /register`, `POST /login` (throttle 10/min), `GET /categories`, `GET /businesses`, `GET /businesses/{id}`
- Firmada: `GET /proofs/{order}` (comprobante privado, enlace de 30 min en `transfer_proof_url`)
- `auth:sanctum`: `GET|PUT /me`, `POST /logout`
- `role:cliente`: CRUD `/addresses`, `GET|POST /orders`, `GET /orders/{id}`, `POST /orders/{id}/cancel`,
  `POST /orders/{id}/proof` (multipart `proof`, solo transferencia), `POST /orders/{id}/rate` (1-5, solo entregado, una vez), `POST /coupons/check`
- `role:repartidor` (prefijo `/driver`): `GET /orders/available`, `GET /orders`, `GET /orders/{id}`,
  `POST /orders/{id}/accept`, `POST /orders/{id}/status`, `POST /location`
- `role:negocio` (prefijo `/business`): `GET /`, `PUT /open`, `GET /orders?active=1`, `GET /orders/{id}`,
  `POST /orders/{id}/status` (aceptado | preparando | listo | cancelado + `reason`), `GET /products`, `PATCH /products/{id}` (available, price), `POST /products/{id}/image`, `PUT /hours` (opens_at, closes_at H:i)

## Reglas de negocio
- Roles de usuario: `admin`, `cliente`, `repartidor`, `negocio` (usa `users.business_id`; login/me incluyen `business`).
- Estados del pedido: `pendiente` → (negocio o admin) `aceptado` → `preparando` → `listo` → (repartidor) `en_camino` → `entregado`.
- Repartidores registrados desde la app quedan con `approved_at` null hasta que el admin los aprueba (Usuarios → Aprobar); `EnsureRole` los bloquea.
- El repartidor solo pasa a `en_camino` desde `listo`; antes de aceptar no ve nombre ni teléfono del cliente.
- Horario: `Business::isOpenNow()` (pausa `is_open` + `opens_at`/`closes_at` en `America/Guayaquil`, admite cruzar medianoche). Se expone como `open_now`.
- Cupones: `Coupon::rejectionFor()` valida, `discountFor()` calcula, `claimUse()` suma el uso de forma atómica.
- Dinero por pedido (se guarda al crearlo, cambiar tarifas no altera el historial): `service_fee` (Setting `service_fee`), `commission` (subtotal × `businesses.commission_rate`), `driver_earning` (envío × Setting `driver_share` %). Total = subtotal + envío + servicio − descuento.
- Ganancia de la plataforma = comisión + servicio + (envío − driver_earning) − descuentos (`PlatformRevenue::totals`). Tarifas en Admin → Ventas → Tarifas (`app/Filament/Pages/PlatformSettings.php`, modelo `Setting` con caché).
- Pago: efectivo (`cash_amount` para el vuelto) o transferencia (datos en `businesses.bank_info`, comprobante en `orders.transfer_proof`, disco public).
- Calificación: `orders.rating` → `Business::refreshRating()` recalcula `rating` y `rating_count`.
- Al cambiar la API, actualizar también `lib/api.dart` y `lib/models.dart` de la app.

## Cuentas de prueba
admin@delivery.test / admin123 · cliente@delivery.test / 123456 · repartidor@delivery.test / 123456 · negocio@delivery.test / 123456

## Antes de producción
- `.env`: `APP_ENV=production`, `APP_DEBUG=false`, `APP_URL=https://...` (las URLs de imágenes y comprobantes salen de aquí).
- Generar claves nuevas de Reverb (`REVERB_APP_KEY/SECRET`) y servirlo detrás de HTTPS (wss).
- Procesos permanentes: `php artisan reverb:start` y `php artisan schedule:run` cada minuto (cron) o `schedule:work`.
- OSRM propio o de pago para rutas (el de demostración no es para producción).
