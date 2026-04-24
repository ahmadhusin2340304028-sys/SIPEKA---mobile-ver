<?php
// app/Http/Middleware/CheckBidangAccess.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\Kegiatan;
use Symfony\Component\HttpFoundation\Response;

/**
 * Middleware: CheckBidangAccess
 *
 * Aturan:
 * - Admin              → boleh semua operasi (CRUD)
 * - Staff Bidang       → hanya boleh CRUD data di bidangnya sendiri
 * - Kadis / Sekretaris → hanya boleh READ (lihat detail)
 *
 * Cara pakai di route:
 *   ->middleware('bidang.access')
 *
 * Middleware ini membaca route parameter {kegiatan} / {id}
 * untuk memverifikasi kepemilikan bidang.
 */
class CheckBidangAccess
{
    // Method HTTP yang dianggap "write" (perlu cek kepemilikan bidang)
    private const WRITE_METHODS = ['POST', 'PUT', 'PATCH', 'DELETE'];

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated.',
            ], 401);
        }

        // Admin: bebas semua
        if ($user->isAdmin()) {
            return $next($request);
        }

        $isWriteRequest = in_array($request->method(), self::WRITE_METHODS);

        // Kadis & Sekretaris: hanya boleh baca
        if ($user->canViewAll() && !$user->isAdmin()) {
            if ($isWriteRequest) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Role Anda hanya dapat melihat data.',
                    'your_role' => $user->role,
                ], 403);
            }
            return $next($request);
        }

        // Staff Bidang: cek kepemilikan bidang untuk write request
        if ($user->isStaffBidang() && $isWriteRequest) {
            $kegiatan = $this->resolveKegiatan($request);

            if ($kegiatan === null) {
                // POST create baru: cek bidang dari request body
                $bidangRequest = $request->input('bidang');
                if ($bidangRequest && $bidangRequest !== $user->getBidang()) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Anda hanya dapat membuat data untuk bidang Anda sendiri.',
                        'bidang_anda'    => $user->getBidang(),
                        'bidang_request' => $bidangRequest,
                    ], 403);
                }
                return $next($request);
            }

            // PUT/PATCH/DELETE: cek bidang kegiatan yang sudah ada
            if (!$user->canManageKegiatan($kegiatan)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak. Kegiatan ini bukan tanggung jawab bidang Anda.',
                    'bidang_anda'     => $user->getBidang(),
                    'bidang_kegiatan' => $kegiatan->bidang,
                ], 403);
            }
        }

        return $next($request);
    }

    /**
     * Cari instance Kegiatan dari route parameter.
     * Support parameter: {kegiatan}, {id}, atau query ?kegiatan_id=
     */
    private function resolveKegiatan(Request $request): ?Kegiatan
    {
        // Route model binding: /kegiatan/{kegiatan}
        $kegiatan = $request->route('kegiatan');
        if ($kegiatan instanceof Kegiatan) {
            return $kegiatan;
        }

        // Route param as ID: /kegiatan/{id}
        $id = $request->route('id') ?? $request->route('kegiatan');
        if ($id && is_numeric($id)) {
            return Kegiatan::find($id);
        }

        // Request body: kegiatan_id (untuk realisasi, bukti, keterangan)
        $kegiatanId = $request->input('kegiatan_id');
        if ($kegiatanId) {
            return Kegiatan::find($kegiatanId);
        }

        return null;
    }
}
