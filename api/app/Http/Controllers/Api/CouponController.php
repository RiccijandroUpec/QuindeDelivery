<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Coupon;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

/** Valida un cupón antes de confirmar el pedido. */
class CouponController extends Controller
{
    public function check(Request $request)
    {
        $data = $request->validate([
            'code' => ['required', 'string', 'max:40'],
            'business_id' => ['required', 'exists:businesses,id'],
            'subtotal' => ['required', 'numeric', 'min:0'],
        ]);

        $business = Business::findOrFail($data['business_id']);
        $coupon = Coupon::findByCode($data['code']);
        $error = $coupon ? $coupon->rejectionFor($request->user(), $business, (float) $data['subtotal']) : 'Ese cupón no existe.';
        if ($error) {
            throw ValidationException::withMessages(['code' => [$error]]);
        }

        return [
            'code' => $coupon->code,
            'description' => $coupon->description,
            'discount' => $coupon->discountFor((float) $data['subtotal'], $business->delivery_fee),
        ];
    }
}
