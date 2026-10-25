# Quinde Delivery (monorepo)

- `app/` – app Flutter (cliente, repartidor, negocio). Detalles en `app/CLAUDE.md`.
- `api/` – backend Laravel + panel Filament. Detalles en `api/CLAUDE.md`.

Al cambiar la API, actualizar también `app/lib/api.dart` y `app/lib/models.dart`.

## Levantar todo en local
1. MySQL de XAMPP en el puerto 3306 (no confundir con otro MySQL en el 3307).
2. En `api/`: `php artisan serve --host=0.0.0.0 --port=8000`, `php artisan reverb:start --host=0.0.0.0 --port=8080` y `php artisan schedule:work`.
3. En `app/`: `flutter run -d chrome`.
