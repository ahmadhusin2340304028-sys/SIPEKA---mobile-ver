<?php
// app/Http/Middleware/CheckRole.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Middleware: CheckRole
 *
 * Penggunaan di route:
 *   ->middleware('role:Admin')
 *   ->middleware('role:Admin,Kepala Dinas')
 *   ->middleware('role:any_staff')   ← semua user yang login
 */
class CheckRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated.',
            ], 401);
        }

        // 'any_staff' = semua role yang sudah login boleh lewat
        if (in_array('any_staff', $roles)) {
            return $next($request);
        }

        if (!in_array($user->role, $roles)) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak. Role Anda tidak memiliki izin untuk aksi ini.',
                'your_role' => $user->role,
                'required_roles' => $roles,
            ], 403);
        }

        return $next($request);
    }
}
