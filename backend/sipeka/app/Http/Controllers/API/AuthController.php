<?php
// app/Http/Controllers/API/AuthController.php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * POST /api/login
     *
     * Login menggunakan username + password (plain text sesuai DB saat ini).
     * Mengembalikan Bearer token (Sanctum).
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('username', $request->username)->first();

        // Cek password — mendukung plain text (sesuai DB sekarang)
        // dan bcrypt (setelah di-hash nanti)
        $passwordValid = false;
        if ($user) {
            if (Hash::needsRehash($user->password)) {
                // Password masih plain text
                $passwordValid = $user->password === $request->password;
            } else {
                $passwordValid = Hash::check($request->password, $user->password);
            }
        }

        if (!$user || !$passwordValid) {
            throw ValidationException::withMessages([
                'username' => ['Username atau password salah.'],
            ]);
        }

        $token = $user->createToken('sipeka-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil.',
            'token'   => $token,
            'user'    => [
                'id'       => $user->id,
                'username' => $user->username,
                'role'     => $user->role,
                'bidang'   => $user->getBidang() ?? "",
                'can_manage' => $user->isAdmin() || $user->isStaffBidang(),
            ],
        ]);
    }

    /**
     * POST /api/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();

        // Hapus hanya token yang sedang dipakai, supaya device lain tetap login.
        // Kalau butuh logout semua device, buat endpoint khusus untuk delete semua token.
        $user?->currentAccessToken()?->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }

    /**
     * GET /api/user
     * Informasi user yang sedang login.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'id'          => $user->id,
                'username'    => $user->username,
                'role'        => $user->role,
                'bidang'      => $user->getBidang() ?? "-",
                'can_manage'  => $user->isAdmin() || $user->isStaffBidang(),
            ],
        ]);
    }
}