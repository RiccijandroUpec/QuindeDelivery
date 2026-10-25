<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/** Acciones del negocio sobre sus propios pedidos. */
class BusinessController extends Controller
{
    /** Estados que el negocio todavía tiene que atender. */
    public const ACTIVE = ['pendiente', 'aceptado', 'preparando', 'listo'];

    /** Desde qué estados puede pasar a cada estado. */
    private const TRANSITIONS = [
        'aceptado' => ['pendiente'],
        'preparando' => ['aceptado'],
        'listo' => ['aceptado', 'preparando'],
        'cancelado' => ['pendiente', 'aceptado', 'preparando'],
    ];

    public function show(Request $request)
    {
        return $this->business($request);
    }

    public function toggleOpen(Request $request)
    {
        $data = $request->validate(['is_open' => ['required', 'boolean']]);
        $business = $this->business($request);
        $business->update($data);

        return $business;
    }

    public function orders(Request $request)
    {
        $query = $this->business($request)->orders()
            ->with(['items', 'driver:id,name,phone,vehicle', 'user:id,name,phone']);

        if ($request->boolean('active')) {
            return $query->whereIn('status', self::ACTIVE)->oldest()->get();
        }

        return $query->latest()->paginate(30);
    }

    public function showOrder(Request $request, Order $order)
    {
        $this->authorizeOrder($request, $order);

        return OrderController::detail($order);
    }

    public function updateStatus(Request $request, Order $order)
    {
        $this->authorizeOrder($request, $order);

        $data = $request->validate([
            'status' => ['required', Rule::in(array_keys(self::TRANSITIONS))],
            'reason' => ['required_if:status,cancelado', 'nullable', 'string', 'max:255'],
        ]);

        if (! in_array($order->status, self::TRANSITIONS[$data['status']])) {
            throw ValidationException::withMessages(['status' => ['No se puede cambiar a ese estado ahora.']]);
        }

        $order->update([
            'status' => $data['status'],
            'cancel_reason' => $data['status'] === 'cancelado' ? $data['reason'] : null,
        ]);

        return OrderController::detail($order);
    }

    public function products(Request $request)
    {
        return $this->business($request)->products()->orderBy('section')->orderBy('name')->get();
    }

    public function updateProduct(Request $request, Product $product)
    {
        abort_unless($product->business_id === $this->business($request)->id, 403);

        $product->update($request->validate([
            'available' => ['sometimes', 'boolean'],
            'price' => ['sometimes', 'numeric', 'min:0.01', 'max:9999'],
        ]));

        return $product;
    }

    private function business(Request $request): Business
    {
        $business = $request->user()->business;
        abort_unless($business, 403, 'Tu cuenta no tiene un negocio asignado.');

        return $business;
    }

    private function authorizeOrder(Request $request, Order $order): void
    {
        abort_unless($order->business_id === $this->business($request)->id, 403);
    }
}
