# Quinde Delivery

Plataforma de delivery multi-negocio para Ecuador, al estilo PedidosYa. Una sola app con tres roles (**cliente**, **repartidor** y **negocio**) y un panel web para el **administrador**, que es el dueño de la plataforma y gana una parte de cada pedido.

| Carpeta | Qué es | Tecnología |
|---|---|---|
| [`app/`](app) | App móvil y web | Flutter 3, Provider, flutter_map (OpenStreetMap), Reverb (WebSockets) |
| [`api/`](api) | API REST y panel de administración | Laravel 12, Filament 5, Sanctum, Laravel Reverb, MySQL |

## Funciones

**Cliente**
- Explora negocios por categoría, arma el carrito y elige su dirección en el mapa.
- Paga en efectivo o por transferencia, con los datos bancarios del negocio y la subida del comprobante.
- Cupones de descuento: porcentaje, monto fijo o envío gratis.
- Sigue su pedido en tiempo real, con la ruta por calle y el tiempo estimado de llegada.
- Califica el pedido y puede repetirlo con un toque.

**Negocio**
- Recibe los pedidos al instante; los acepta o los rechaza con un motivo.
- Los marca como "preparando" y "listo".
- Abre y cierra con un interruptor o con un horario automático.
- Maneja su menú: marca productos como agotados, cambia precios y sube fotos.
- Ve su historial, sus ventas y la comisión de la semana.

**Repartidor**
- Necesita la aprobación del admin antes de trabajar.
- Se conecta, ve los pedidos disponibles y toma uno.
- Comparte su ubicación cada 10 s y solo puede recoger el pedido cuando el negocio lo marcó listo.
- Ve sus ganancias.

**Administrador** (`/admin`)
- Panel con métricas: ventas, pedidos por estado, los negocios que más venden y el tiempo promedio de entrega.
- Gestión de negocios, productos, categorías, usuarios (con la aprobación de repartidores), pedidos y cupones.
- **Tarifas**: tarifa de servicio por pedido y porcentaje del envío para el repartidor. La comisión se define por negocio.
- **Liquidaciones**: la ganancia de la plataforma, lo que debe cada negocio y lo que cobró y debe entregar cada repartidor.

### Cómo gana la plataforma
Con un pedido de ejemplo de $10 en productos, $1.50 de envío y las tarifas por defecto:

| | Cliente paga | Negocio | Repartidor | Plataforma |
|---|---|---|---|---|
| Productos | $10.00 | $9.00 | | $1.00 (comisión 10 %) |
| Envío | $1.50 | | $1.20 (80 %) | $0.30 |
| Tarifa de servicio | $0.25 | | | $0.25 |

Cada pedido guarda su propio reparto, así que cambiar las tarifas no altera el historial.

## Cómo correrlo en local

Requisitos: PHP 8.2+, Composer, MySQL (por ejemplo, el de XAMPP) y Flutter 3.x.

**1. Backend**
```bash
cd api
composer install
cp .env.example .env          # configurar la base de datos MySQL
php artisan key:generate
php artisan migrate --seed    # crea datos y cuentas de prueba
php artisan storage:link
```
Luego, en tres terminales:
```bash
php artisan serve --host=0.0.0.0 --port=8000        # API + panel: http://localhost:8000/admin
php artisan reverb:start --host=0.0.0.0 --port=8080 # tiempo real
php artisan schedule:work                           # cancela pedidos que el negocio no acepta en 10 min
```
Para Reverb, completa en el `.env` `REVERB_APP_ID`, `REVERB_APP_KEY` y `REVERB_APP_SECRET` con valores aleatorios.

**2. App**
```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=REVERB_KEY=<tu REVERB_APP_KEY>
```
- Emulador Android: usa `http://10.0.2.2:8000/api` automáticamente.
- Celular físico: `--dart-define=API_URL=http://IP-DE-TU-PC:8000/api`.

## Cuentas de prueba

| Rol | Correo | Clave |
|---|---|---|
| Admin | admin@delivery.test | admin123 |
| Cliente | cliente@delivery.test | 123456 |
| Repartidor | repartidor@delivery.test | 123456 |
| Negocio | negocio@delivery.test | 123456 |

Cupones de prueba: `PRIMERA20`, `ENVIOGRATIS` y `QUINDE2`.

## Flujo de un pedido
`pendiente` → (negocio) `aceptado` → `preparando` → `listo` → (repartidor) `en_camino` → `entregado`

El negocio puede rechazarlo con un motivo antes de que esté listo, y si no responde en 10 minutos se cancela solo.

## Tests
```bash
cd api && php artisan test   # 37 tests: flujo completo, permisos, cupones, tiempo real, tarifas…
cd app && flutter test       # 23 tests: modelos, carrito y widgets
```

## Antes de producción
- `api/.env`: `APP_ENV=production`, `APP_DEBUG=false`, `APP_URL=https://…`, y claves nuevas de Reverb servido con HTTPS (wss).
- Usar un servidor OSRM propio para las rutas (el de demostración es solo para pruebas).
- En Android, quitar `usesCleartextTraffic` y cambiar el `applicationId` antes de publicar.
- Pendiente: notificaciones push (Firebase), pagos con tarjeta, facturación electrónica SRI y recuperación de contraseña.
