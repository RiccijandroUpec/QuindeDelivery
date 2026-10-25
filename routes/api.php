<?php

use App\Http\Controllers\Api\AddressController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BusinessController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\CouponController;
use App\Http\Controllers\Api\DriverController;
use App\Http\Controllers\Api\OrderController;
use Illuminate\Support\Facades\Route;

// Límite de intentos para frenar ataques de fuerza bruta.
Route::middleware('throttle:10,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

// Comprobantes de transferencia: solo con enlace firmado (ver Order::getTransferProofUrlAttribute).
Route::get('/proofs/{order}', [OrderController::class, 'showProof'])->middleware('signed')->name('orders.proof');

Route::get('/categories', [CatalogController::class, 'categories']);
Route::get('/businesses', [CatalogController::class, 'businesses']);
Route::get('/businesses/{business}', [CatalogController::class, 'business']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/me', [AuthController::class, 'updateProfile']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::middleware('role:cliente')->group(function () {
        Route::apiResource('addresses', AddressController::class)->except('show');
        Route::get('/orders', [OrderController::class, 'index']);
        Route::post('/orders', [OrderController::class, 'store'])->middleware('throttle:10,1');
        Route::post('/coupons/check', [CouponController::class, 'check'])->middleware('throttle:20,1');
        Route::get('/orders/{order}', [OrderController::class, 'show']);
        Route::post('/orders/{order}/cancel', [OrderController::class, 'cancel']);
        Route::post('/orders/{order}/proof', [OrderController::class, 'uploadProof']);
        Route::post('/orders/{order}/rate', [OrderController::class, 'rate']);
    });

    Route::middleware('role:repartidor')->prefix('driver')->group(function () {
        Route::get('/orders/available', [DriverController::class, 'available']);
        Route::get('/orders', [DriverController::class, 'mine']);
        Route::get('/orders/{order}', [DriverController::class, 'show']);
        Route::post('/orders/{order}/accept', [DriverController::class, 'accept']);
        Route::post('/orders/{order}/status', [DriverController::class, 'updateStatus']);
        Route::post('/location', [DriverController::class, 'location']);
    });

    Route::middleware('role:negocio')->prefix('business')->group(function () {
        Route::get('/', [BusinessController::class, 'show']);
        Route::put('/open', [BusinessController::class, 'toggleOpen']);
        Route::get('/orders', [BusinessController::class, 'orders']);
        Route::get('/orders/{order}', [BusinessController::class, 'showOrder']);
        Route::post('/orders/{order}/status', [BusinessController::class, 'updateStatus']);
        Route::get('/products', [BusinessController::class, 'products']);
        Route::patch('/products/{product}', [BusinessController::class, 'updateProduct']);
        Route::post('/products/{product}/image', [BusinessController::class, 'uploadProductImage']);
        Route::put('/hours', [BusinessController::class, 'updateHours']);
    });
});
