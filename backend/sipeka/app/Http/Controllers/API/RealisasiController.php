<?php
// app/Http/Controllers/API/RealisasiController.php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\BuktiKegiatan;
use App\Models\Kegiatan;
use App\Models\KeteranganKegiatan;
use App\Models\RealisasiAnggaran;
use App\Models\RealisasiFisik;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class RealisasiController extends Controller
{
    // ─── GET Realisasi per Kegiatan ───────────────────────────────────────────

    /**
     * GET /api/kegiatan/{id}/realisasi
     * Semua data realisasi (fisik + anggaran + keterangan + bukti) per kegiatan.
     */
    public function index(int $id, Request $request): JsonResponse
    {
        $user     = $request->user();
        $kegiatan = Kegiatan::findOrFail($id);

        // Data realisasi bersifat read-only, jadi semua role yang login boleh melihat.
        // Hak input/update tetap dicek di endpoint store/upload/destroy.

        $fisik     = RealisasiFisik::where('kegiatan_id', $id)->orderBy('bulan')->get();
        $anggaran  = RealisasiAnggaran::where('kegiatan_id', $id)->orderBy('bulan')->get();
        $keterangan = KeteranganKegiatan::where('kegiatan_id', $id)->orderBy('bulan')->get();
        $bukti     = BuktiKegiatan::where('kegiatan_id', $id)->orderBy('bulan')->get()
            ->map(fn($b) => array_merge($b->toArray(), ['file_url' => $b->file_url]));

        // Gabungkan per bulan untuk kemudahan frontend
        $bulanData = [];
        for ($b = 1; $b <= 12; $b++) {
            $bulanData[$b] = [
                'bulan'          => $b,
                'nama_bulan'     => $this->namaBulan($b),
                'fisik'          => optional($fisik->firstWhere('bulan', $b))->nilai,
                'anggaran'       => optional($anggaran->firstWhere('bulan', $b))->nilai,
                'keterangan'     => optional($keterangan->firstWhere('bulan', $b))->keterangan,
                'bukti'          => optional($bukti->firstWhere('bulan', $b)),
            ];
        }

        return response()->json([
            'success' => true,
            'data' => [
                'kegiatan_id'    => $id,
                'kegiatan_nama'  => $kegiatan->kegiatan,
                'pagu_anggaran'  => $kegiatan->pagu_anggaran,
                'per_bulan'      => array_values($bulanData),
                'total_fisik'    => $kegiatan->total_realisasi_fisik,
                'total_anggaran' => $kegiatan->total_realisasi_anggaran,
                'persen_anggaran' => $kegiatan->persen_anggaran,
            ],
        ]);
    }

    // ─── POST: Simpan Realisasi Fisik + Anggaran + Keterangan ────────────────

    /**
     * POST /api/realisasi
     *
     * Menyimpan realisasi fisik, anggaran, dan keterangan sekaligus.
     * Staff bidang hanya bisa simpan untuk kegiatan bidangnya.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'kegiatan_id'        => 'required|integer|exists:kegiatan,id',
            'bulan'              => 'required|integer|min:1|max:12',
            'realisasi_fisik'    => 'required|numeric|min:0|max:100',
            'realisasi_anggaran' => 'required|numeric|min:0',
            'keterangan'         => 'nullable|string|max:2000',
        ]);

        $user     = $request->user();
        $kegiatan = Kegiatan::findOrFail($validated['kegiatan_id']);

        // Cek hak akses bidang
        if ($user->isStaffBidang() && !$user->canManageKegiatan($kegiatan)) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak berwenang menginput realisasi untuk kegiatan ini.',
                'bidang_anda'     => $user->getBidang(),
                'bidang_kegiatan' => $kegiatan->bidang,
            ], 403);
        }

        DB::transaction(function () use ($validated) {
            // Upsert realisasi fisik
            RealisasiFisik::updateOrCreate(
                [
                    'kegiatan_id' => $validated['kegiatan_id'],
                    'bulan'       => $validated['bulan'],
                ],
                ['nilai' => $validated['realisasi_fisik']]
            );

            // Upsert realisasi anggaran
            RealisasiAnggaran::updateOrCreate(
                [
                    'kegiatan_id' => $validated['kegiatan_id'],
                    'bulan'       => $validated['bulan'],
                ],
                ['nilai' => $validated['realisasi_anggaran']]
            );

            // Upsert keterangan (opsional)
            if (isset($validated['keterangan'])) {
                KeteranganKegiatan::updateOrCreate(
                    [
                        'kegiatan_id' => $validated['kegiatan_id'],
                        'bulan'       => $validated['bulan'],
                    ],
                    ['keterangan' => $validated['keterangan']]
                );
            }
        });

        return response()->json([
            'success' => true,
            'message' => "Realisasi bulan {$this->namaBulan($validated['bulan'])} berhasil disimpan.",
        ], 201);
    }

    // ─── POST: Upload Bukti Kegiatan ──────────────────────────────────────────

    /**
     * POST /api/upload-bukti
     *
     * Upload file bukti kegiatan (PDF/JPG/PNG).
     * Staff bidang hanya bisa upload untuk kegiatan bidangnya.
     */
    public function uploadBukti(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'kegiatan_id' => 'required|integer|exists:kegiatan,id',
            'bulan'       => 'required|integer|min:1|max:12',
            'file'        => 'required|file|mimes:pdf,jpg,jpeg,png|max:5120', // 5MB
        ]);

        $user     = $request->user();
        $kegiatan = Kegiatan::findOrFail($validated['kegiatan_id']);

        if ($user->isStaffBidang() && !$user->canManageKegiatan($kegiatan)) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak.',
            ], 403);
        }

        // Hapus file lama jika ada
        $existing = BuktiKegiatan::where('kegiatan_id', $validated['kegiatan_id'])
            ->where('bulan', $validated['bulan'])
            ->first();

        if ($existing && Storage::disk('public')->exists($existing->file_path)) {
            Storage::disk('public')->delete($existing->file_path);
        }

        // Simpan file baru
        $path = $request->file('file')->store(
            "bukti/{$validated['kegiatan_id']}",
            'public'
        );

        BuktiKegiatan::updateOrCreate(
            [
                'kegiatan_id' => $validated['kegiatan_id'],
                'bulan'       => $validated['bulan'],
            ],
            ['file_path' => $path]
        );

        return response()->json([
            'success'  => true,
            'message'  => 'Bukti berhasil diunggah.',
            'file_url' => asset('storage/' . $path),
        ], 201);
    }

    // ─── DELETE: Hapus Realisasi Bulan ────────────────────────────────────────

    /**
     * DELETE /api/realisasi/{kegiatan_id}/{bulan}
     * Hanya admin atau staff bidang pemilik kegiatan.
     */
    public function destroy(int $kegiatanId, int $bulan, Request $request): JsonResponse
    {
        $user     = $request->user();
        $kegiatan = Kegiatan::findOrFail($kegiatanId);

        if ($user->isStaffBidang() && !$user->canManageKegiatan($kegiatan)) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak.',
            ], 403);
        }

        DB::transaction(function () use ($kegiatanId, $bulan) {
            RealisasiFisik::where('kegiatan_id', $kegiatanId)->where('bulan', $bulan)->delete();
            RealisasiAnggaran::where('kegiatan_id', $kegiatanId)->where('bulan', $bulan)->delete();
            KeteranganKegiatan::where('kegiatan_id', $kegiatanId)->where('bulan', $bulan)->delete();

            $bukti = BuktiKegiatan::where('kegiatan_id', $kegiatanId)->where('bulan', $bulan)->first();
            if ($bukti) {
                Storage::disk('public')->delete($bukti->file_path);
                $bukti->delete();
            }
        });

        return response()->json([
            'success' => true,
            'message' => "Realisasi bulan {$this->namaBulan($bulan)} berhasil dihapus.",
        ]);
    }

    // ─── Helper ───────────────────────────────────────────────────────────────

    private function namaBulan(int $bulan): string
    {
        $list = [
            1 => 'Januari', 2 => 'Februari', 3 => 'Maret',
            4 => 'April',   5 => 'Mei',       6 => 'Juni',
            7 => 'Juli',    8 => 'Agustus',   9 => 'September',
            10 => 'Oktober', 11 => 'November', 12 => 'Desember',
        ];
        return $list[$bulan] ?? '-';
    }
}
