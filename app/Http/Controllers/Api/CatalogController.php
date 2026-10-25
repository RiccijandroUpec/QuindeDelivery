<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Category;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public function categories()
    {
        return Category::orderBy('sort')->get();
    }

    public function businesses(Request $request)
    {
        return Business::query()
            ->with('category:id,name')
            ->where('active', true)
            ->when($request->category_id, fn ($q, $id) => $q->where('category_id', $id))
            ->when($request->featured, fn ($q) => $q->where('featured', true))
            ->when($request->search, function ($q, $search) {
                $q->where(function ($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                        ->orWhereHas('products', fn ($p) => $p->where('name', 'like', "%{$search}%"));
                });
            })
            ->orderByDesc('is_open')
            ->orderByDesc('featured')
            ->orderByDesc('rating')
            ->get();
    }

    public function business(Business $business)
    {
        abort_unless($business->active, 404);

        return $business->load([
            'category:id,name',
            'products' => fn ($q) => $q->where('available', true)->orderBy('section')->orderBy('name'),
        ]);
    }
}
