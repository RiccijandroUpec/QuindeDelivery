<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/** Pedidos del cliente. */
class OrderController extends Controller
{
    public function index(Request $request)
    {
        return $request->user()->orders()
            ->with(['business:id,name,logo', 'items'])
            ->latest()
            ->paginate(20);
    }

    public function show(Request $request, Order $order)
    {
        abort_unless($order->user_id === $request->user()->id, 403);

        return $this->detail($order);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'business_id' => ['required', 'exists:businesses,id'],
            'address' => ['required', 'string', 'max:255'],
            'reference' => ['nullable', 'string', 'max:255'],
            'lat' => ['required', 'numeric'],
            'lng' => ['required', 'numeric'],
            'payment_method' => ['required', Rule::in(['efectivo', 'transferencia'])],
            'cash_amount' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:500'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:99'],
            'items.*.notes' => ['nullable', 'string', 'max:255'],
        ]);

        $business = Business::findOrFail($data['business_id']);
        if (! $business->active || ! $business->is_open) {
            throw ValidationException::withMessages(['business_id' => ['El negocio está cerrado en este momento.']]);
        }

        // Los precios se toman de la base de datos, nunca del cliente.
        $products = Product::where('business_id', $business->id)
            ->where('available', true)
            ->whereIn('id', collect($data['items'])->pluck('product_id'))
            ->get()
            ->keyBy('id');

        $items = [];
        $subtotal = 0;
        foreach ($data['items'] as $item) {
            $product = $products->get($item['product_id']);
            if (! $product) {
                throw ValidationException::withMessages(['items' => ['Uno de los productos ya no está disponible.']]);
            }
            $lineTotal = round($product->price * $item['quantity'], 2);
            $subtotal += $lineTotal;
            $items[] = [
                'product_id' => $product->id,
                'name' => $product->name,
                'price' => $product->price,
                'quantity' => $item['quantity'],
                'subtotal' => $lineTotal,
                'notes' => $item['notes'] ?? null,
            ];
        }

        if ($subtotal < $business->min_order) {
            throw ValidationException::withMessages(['items' => ["El pedido mínimo es \${$business->min_order}."]]);
        }

        $total = round($subtotal + $business->delivery_fee, 2);
        if ($data['payment_method'] === 'efectivo' && isset($data['cash_amount']) && $data['cash_amount'] < $total) {
            throw ValidationException::withMessages(['cash_amount' => ['El monto en efectivo no cubre el total.']]);
        }

        $order = DB::transaction(function () use ($request, $data, $business, $items, $subtotal, $total) {
            $order = Order::create([
                'user_id' => $request->user()->id,
                'business_id' => $business->id,
                'status' => 'pendiente',
                'address' => $data['address'],
                'reference' => $data['reference'] ?? null,
                'lat' => $data['lat'],
                'lng' => $data['lng'],
                'subtotal' => $subtotal,
                'delivery_fee' => $business->delivery_fee,
                'total' => $total,
                'payment_method' => $data['payment_method'],
                'cash_amount' => $data['cash_amount'] ?? null,
                'notes' => $data['notes'] ?? null,
            ]);
            $order->items()->createMany($items);

            return $order;
        });

        return response()->json($this->detail($order), 201);
    }

    public function cancel(Request $request, Order $order)
    {
        abort_unless($order->user_id === $request->user()->id, 403);
        if ($order->status !== 'pendiente') {
            throw ValidationException::withMessages(['status' => ['Solo puedes cancelar pedidos que aún no fueron aceptados.']]);
        }
        $order->update(['status' => 'cancelado', 'cancel_reason' => 'Cancelado por el cliente']);

        return $this->detail($order);
    }

    public function uploadProof(Request $request, Order $order)
    {
        abort_unless($order->user_id === $request->user()->id, 403);
        if ($order->payment_method !== 'transferencia' || ! in_array($order->status, ['pendiente', 'aceptado', 'preparando', 'listo', 'en_camino'])) {
            throw ValidationException::withMessages(['proof' => ['Este pedido no necesita comprobante.']]);
        }

        $request->validate(['proof' => ['required', 'image', 'max:5120']]);

        if ($order->transfer_proof) {
            Storage::disk('public')->delete($order->transfer_proof);
        }
        $order->update(['transfer_proof' => $request->file('proof')->store('proofs', 'public')]);

        return $this->detail($order);
    }

    public function rate(Request $request, Order $order)
    {
        abort_unless($order->user_id === $request->user()->id, 403);
        $data = $request->validate([
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:255'],
        ]);
        if ($order->status !== 'entregado' || $order->rating !== null) {
            throw ValidationException::withMessages(['rating' => ['Este pedido ya no se puede calificar.']]);
        }

        $order->update(['rating' => $data['rating'], 'rating_comment' => $data['comment'] ?? null]);
        $order->business->refreshRating();

        return $this->detail($order);
    }

    public static function detail(Order $order): Order
    {
        return $order->load([
            'items',
            'business:id,name,logo,address,phone,bank_info,lat,lng',
            'driver:id,name,phone,vehicle',
            'user:id,name,phone',
        ]);
    }
}
