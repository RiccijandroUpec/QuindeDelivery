<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/** Acciones del repartidor. */
class DriverController extends Controller
{
    public function available()
    {
        return Order::query()
            ->whereNull('driver_id')
            ->whereIn('status', Order::AVAILABLE_FOR_DRIVER)
            ->with(['business:id,name,logo,address,lat,lng', 'items'])
            ->oldest()
            ->get();
    }

    public function mine(Request $request)
    {
        return $request->user()->deliveries()
            ->with(['business:id,name,logo,address,lat,lng', 'items', 'user:id,name,phone'])
            ->when($request->boolean('active'), fn ($q) => $q->whereNotIn('status', ['entregado', 'cancelado']))
            ->latest()
            ->paginate(20);
    }

    public function show(Request $request, Order $order)
    {
        $this->authorizeDriver($request, $order, allowUnassigned: true);

        return OrderController::detail($order);
    }

    public function accept(Request $request, Order $order)
    {
        $driver = $request->user();

        // Bloqueo para que dos repartidores no tomen el mismo pedido.
        $taken = DB::transaction(function () use ($order, $driver) {
            $fresh = Order::whereKey($order->id)->lockForUpdate()->first();
            if ($fresh->driver_id || ! in_array($fresh->status, Order::AVAILABLE_FOR_DRIVER)) {
                return false;
            }
            $fresh->update(['driver_id' => $driver->id]);

            return true;
        });

        if (! $taken) {
            throw ValidationException::withMessages(['order' => ['Otro repartidor ya tomó este pedido.']]);
        }

        return OrderController::detail($order->refresh());
    }

    public function updateStatus(Request $request, Order $order)
    {
        $this->authorizeDriver($request, $order);

        $data = $request->validate([
            'status' => ['required', Rule::in(['en_camino', 'entregado'])],
        ]);

        $allowed = [
            'en_camino' => ['listo'], // solo cuando el negocio lo marcó listo
            'entregado' => ['en_camino'],
        ];
        if (! in_array($order->status, $allowed[$data['status']])) {
            $message = $data['status'] === 'en_camino'
                ? 'El negocio todavía no marca el pedido como listo.'
                : 'No se puede cambiar a ese estado ahora.';
            throw ValidationException::withMessages(['status' => [$message]]);
        }

        $order->update([
            'status' => $data['status'],
            'delivered_at' => $data['status'] === 'entregado' ? now() : null,
        ]);

        return OrderController::detail($order);
    }

    public function location(Request $request)
    {
        $data = $request->validate([
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
        ]);

        $updated = $request->user()->deliveries()
            ->whereIn('status', ['aceptado', 'preparando', 'listo', 'en_camino'])
            ->update([
                'driver_lat' => $data['lat'],
                'driver_lng' => $data['lng'],
                'driver_location_at' => now(),
            ]);

        return response()->json(['updated' => $updated]);
    }

    private function authorizeDriver(Request $request, Order $order, bool $allowUnassigned = false): void
    {
        $mine = $order->driver_id === $request->user()->id;
        $open = $allowUnassigned && $order->driver_id === null && in_array($order->status, Order::AVAILABLE_FOR_DRIVER);
        abort_unless($mine || $open, 403);
    }
}
