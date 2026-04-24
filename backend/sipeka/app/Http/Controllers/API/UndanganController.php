<?php
// app/Http/Controllers/API/UndanganController.php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Undangan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class UndanganController extends Controller
{
    /**
     * GET /api/undangan
     *
     * Staff bidang → hanya undangan sesuai bidangnya (bidang_terkait).
     * Admin/Kadis/Sekretaris → semua undangan.
     *
     * Query:
     *   ?status=   → filter status_kegiatan
     *   ?menghadiri= → filter menghadiri
     *   ?per_page=
     */
    public function index(Request $request): JsonResponse
    {
        $user  = $request->user();
        $query = Undangan::query();

        // Bidang filter untuk staff
        if ($user->isStaffBidang()) {
            $query->where('bidang_terkait', $user->getBidang());
        }

        if ($request->filled('status')) {
            $query->where('status_kegiatan', $request->status);
        }

        if ($request->filled('menghadiri')) {
            $query->where('menghadiri', $request->menghadiri);
        }

        $undangan = $query
            ->orderByDesc('tanggal')
            ->paginate($request->get('per_page', 20));

        // Tambah field bukti_url
        $undangan->getCollection()->transform(function ($item) {
            $item->bukti_url = $item->bukti_url;
            return $item;
        });

        return response()->json([
            'success' => true,
            'data'    => $undangan,
        ]);
    }

    /**
     * GET /api/undangan/{id}
     */
    public function show(int $id, Request $request): JsonResponse
    {
        $user     = $request->user();
        $undangan = Undangan::findOrFail($id);

        if ($user->isStaffBidang() && $undangan->bidang_terkait !== $user->getBidang()) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'data'    => array_merge($undangan->toArray(), [
                'bukti_url' => $undangan->bukti_url,
            ]),
        ]);
    }

    /**
     * POST /api/undangan
     * Admin + staff bidang bisa membuat undangan (sesuai bidangnya).
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'judul_kegiatan'  => 'required|string|max:255',
            'tanggal'         => 'required|date',
            'waktu'           => 'required|date_format:H:i',
            'tempat'          => 'required|string|max:255',
            'pihak_mengundang' => 'required|string|max:255',
            'bidang_terkait'  => 'required|string|max:150',
            'delegasi'        => 'nullable|string|max:255',
        ]);

        // Staff hanya bisa buat undangan untuk bidangnya
        if ($user->isStaffBidang() && $validated['bidang_terkait'] !== $user->getBidang()) {
            return response()->json([
                'success' => false,
                'message' => 'Anda hanya dapat membuat undangan untuk bidang Anda.',
            ], 403);
        }

        $undangan = Undangan::create(array_merge($validated, [
            'status_kegiatan' => Undangan::STATUS_BELUM,
            'menghadiri'      => Undangan::HADIR_PENDING,
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil ditambahkan.',
            'data'    => $undangan,
        ], 201);
    }

    /**
     * PUT /api/undangan/{id}
     * Admin bisa edit semua. Staff bidang hanya miliknya.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user     = $request->user();
        $undangan = Undangan::findOrFail($id);

        if ($user->isStaffBidang() && $undangan->bidang_terkait !== $user->getBidang()) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak.',
            ], 403);
        }

        $validated = $request->validate([
            'judul_kegiatan'  => 'sometimes|string|max:255',
            'tanggal'         => 'sometimes|date',
            'waktu'           => 'sometimes|date_format:H:i',
            'tempat'          => 'sometimes|string|max:255',
            'pihak_mengundang' => 'sometimes|string|max:255',
            'bidang_terkait'  => 'sometimes|string|max:150',
            'status_kegiatan' => 'sometimes|string|max:50',
            'menghadiri'      => 'sometimes|string|in:Hadir,Tidak Hadir,Delegasi,Pending',
            'delegasi'        => 'nullable|string|max:255',
        ]);

        $undangan->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil diperbarui.',
            'data'    => $undangan,
        ]);
    }

    /**
     * POST /api/undangan/{id}/kehadiran
     * Update status kehadiran + upload bukti.
     */
    public function updateKehadiran(Request $request, int $id): JsonResponse
    {
        $user     = $request->user();
        $undangan = Undangan::findOrFail($id);

        if ($user->isStaffBidang() && $undangan->bidang_terkait !== $user->getBidang()) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak.',
            ], 403);
        }

        $validated = $request->validate([
            'menghadiri' => 'required|string|in:Hadir,Tidak Hadir,Delegasi',
            'delegasi'   => 'nullable|string|max:255',
            'bukti'      => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        // Upload bukti jika ada
        if ($request->hasFile('bukti')) {
            // Hapus file lama
            if ($undangan->bukti && Storage::disk('public')->exists($undangan->bukti)) {
                Storage::disk('public')->delete($undangan->bukti);
            }
            $validated['bukti'] = $request->file('bukti')->store('bukti-undangan', 'public');
        }

        $validated['status_kegiatan'] = Undangan::STATUS_SELESAI;

        $undangan->update($validated);

        return response()->json([
            'success' => true,
            'message' => "Status kehadiran berhasil diperbarui: {$validated['menghadiri']}.",
            'data'    => array_merge($undangan->toArray(), [
                'bukti_url' => $undangan->bukti_url,
            ]),
        ]);
    }

    /**
     * DELETE /api/undangan/{id}
     * Admin saja.
     */
    public function destroy(int $id): JsonResponse
    {
        $undangan = Undangan::findOrFail($id);

        if ($undangan->bukti && Storage::disk('public')->exists($undangan->bukti)) {
            Storage::disk('public')->delete($undangan->bukti);
        }

        $undangan->delete();

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil dihapus.',
        ]);
    }
}
