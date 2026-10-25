<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:20'],
            'password' => ['required', 'string', 'min:8', 'max:100'],
            'role' => ['nullable', Rule::in(['cliente', 'repartidor'])],
            'vehicle' => ['nullable', 'string', 'max:50'],
        ]);

        $role = $data['role'] ?? 'cliente';
        $user = User::create([
            ...$data,
            'role' => $role,
            'approved_at' => $role === 'repartidor' ? null : now(),
        ]);

        if ($user->isPendingApproval()) {
            return response()->json([
                'pending' => true,
                'message' => '¡Listo! Revisaremos tus datos y te avisaremos cuando tu cuenta de repartidor esté aprobada.',
            ], 201);
        }

        return response()->json([
            'token' => $user->createToken('app')->plainTextToken,
            'user' => $this->withBusiness($user),
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Correo o contraseña incorrectos.'],
            ]);
        }

        if (! $user->active) {
            throw ValidationException::withMessages([
                'email' => ['Tu cuenta está desactivada.'],
            ]);
        }

        if ($user->isPendingApproval()) {
            throw ValidationException::withMessages([
                'email' => ['Tu cuenta de repartidor está en revisión. Te avisaremos cuando sea aprobada.'],
            ]);
        }

        return response()->json([
            'token' => $user->createToken('app')->plainTextToken,
            'user' => $this->withBusiness($user),
        ]);
    }

    public function me(Request $request)
    {
        return $this->withBusiness($request->user());
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:20'],
            'vehicle' => ['nullable', 'string', 'max:50'],
        ]);
        $user->update($data);

        return $this->withBusiness($user);
    }

    /** Los usuarios de negocio reciben su negocio junto con el perfil. */
    private function withBusiness(User $user): User
    {
        return $user->role === 'negocio' ? $user->load('business:id,name,logo,is_open') : $user;
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Sesión cerrada']);
    }
}
