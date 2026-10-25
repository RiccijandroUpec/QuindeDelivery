# Colibrí Delivery – App Flutter

App de delivery multi-negocio, una sola app con tres roles: **cliente**, **repartidor** y **negocio**.
Backend Laravel en `C:\xampp\htdocs\delivery-api` (tiene su propio CLAUDE.md).

## Comandos
- Correr: `flutter run -d chrome` (o `-d <dispositivo>`)
- Celular físico / server remoto: `flutter run --dart-define=API_URL=http://IP:8000/api`
- APK: `flutter build apk --release --dart-define=API_URL=https://.../api`
- Análisis: `flutter analyze` · Tests: `flutter test`

## Estructura (lib/)
- `config.dart` – `AppConfig.apiUrl` (web → localhost, emulador Android → 10.0.2.2, o `API_URL`)
- `api.dart` – cliente HTTP único (token Sanctum en header Bearer)
- `models.dart` – todos los modelos
- `theme.dart` – colores/tema
- `state/` – `auth_state`, `cart_state`, `location_service` (Provider)
- `widgets/` – `brand` (logo, `HoveringBird` animado, `BirdLoader`, `PolyBackground`, `StatusChip`, `CallButton`, `StarRating`), `cart_bar`, `order_map` (flutter_map + OSM), `order_summary`
- `screens/auth/` – login, registro
- `screens/client/` – shell, home, negocio, checkout, address_picker, orders, order_tracking
- `screens/driver/` – shell, available_orders, driver_order, my_deliveries
- `screens/business/` – shell, business_orders (aceptar/rechazar/preparar/listo, abrir/cerrar, ver comprobante), business_menu (agotado/precio), business_history
- `screens/profile_screen.dart` – compartido

## Convenciones
- Estado con `provider`; HTTP con `http`; persistencia con `shared_preferences`.
- Mapas: `flutter_map` + `latlong2` (sin Google Maps). GPS: `geolocator`.
- Textos de la UI en español.
- Estilo premium: colores y tema en `theme.dart` (`AppColors.night/gold/brandGradient`, fuente Plus Jakarta Sans). Cargas de página con `BirdLoader`, no `CircularProgressIndicator`.
- Llamadas con `url_launcher` (`callPhone`), fotos con `image_picker` + `Api.upload`.
- Sin websockets: seguimiento por polling (cliente cada 8 s, repartidor envía ubicación cada 10 s).

## Flujo de pedido
`pendiente` → (negocio) `aceptado` → `preparando` → `listo` → (repartidor) `en_camino` → `entregado`
El negocio puede rechazar (`cancelado` + `cancel_reason`) hasta antes de `listo`. El admin también puede mover estados desde el panel.

## Cuentas de prueba
admin@delivery.test / admin123 · cliente@delivery.test / 123456 · repartidor@delivery.test / 123456 · negocio@delivery.test / 123456 (Sabor Serrano)
