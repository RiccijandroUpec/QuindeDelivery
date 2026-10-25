# Quinde Delivery – App Flutter

App de delivery multi-negocio con dos roles en una sola app: **cliente** y **repartidor**.
El backend (API + panel admin Filament) está en `C:\xampp\htdocs\delivery-api`.

## Cómo correr todo

1. Arranca MySQL de XAMPP (puerto 3306).
2. Backend:
   ```
   cd C:\xampp\htdocs\delivery-api
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   Panel admin: http://localhost:8000/admin
   En otras dos terminales (tiempo real y pedidos vencidos):
   ```
   php artisan reverb:start --host=0.0.0.0 --port=8080
   php artisan schedule:work
   ```
3. App:
   ```
   flutter run -d chrome
   ```
   - Emulador Android: usa `http://10.0.2.2:8000/api` automáticamente.
   - Celular físico: `flutter run --dart-define=API_URL=http://IP-DE-TU-PC:8000/api`

## Cuentas de prueba

| Rol        | Correo                     | Clave    |
|------------|----------------------------|----------|
| Admin      | admin@delivery.test        | admin123 |
| Cliente    | cliente@delivery.test      | 123456   |
| Repartidor | repartidor@delivery.test   | 123456   |
| Negocio    | negocio@delivery.test      | 123456   |

## Flujo de un pedido

`pendiente` → (negocio) `aceptado` → `preparando` → `listo` → (repartidor lo toma) → `en_camino` → `entregado`

- El cliente arma el carrito, elige dirección en el mapa y paga en efectivo o por transferencia.
- El negocio (rol *negocio*) acepta o rechaza con motivo, y marca *preparando* y *listo* desde la app. El admin también puede hacerlo desde el panel.
- El repartidor se pone *En línea*, ve los pedidos disponibles, acepta uno y su ubicación se envía cada 10 s.
- El cliente ve el estado y al repartidor en el mapa (se actualiza cada 8 s).

## Estructura

```
lib/
  config.dart        URL de la API
  api.dart           cliente HTTP
  models.dart        modelos
  theme.dart         colores y tema
  state/             sesión, carrito, ubicación del repartidor
  widgets/           logo, fondos de polígonos, mapa, etc.
  screens/auth/      login y registro
  screens/client/    inicio, negocio, checkout, seguimiento
  screens/driver/    pedidos disponibles, entrega en curso
assets/logo.svg      colibrí low-poly
```
