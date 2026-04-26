<?php
// app/Http/Controllers/API/KegiatanController.php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Kegiatan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class KegiatanController extends Controller
{
    /**
     * GET /api/kegiatan
     *
     * Staff bidang → hanya tampil kegiatan sesuai bidangnya.
     * Admin/Kadis/Sekretaris → tampil semua.
     *
     * Query params:
     *   ?search=   → cari di kolom kegiatan, sub_kegiatan, program
     *   ?bidang=   → filter bidang (admin only)
     *   ?tahun=    → filter tahun
     *   ?per_page= → pagination (default 20)
     */
    public function index(Request $request): JsonResponse
    {
        $user  = $request->user();
        $query = Kegiatan::query();

        // ── Bidang Filter (access control) ──────────────────────────────────
        // if ($user->isStaffBidang()) {
        //     // Staff hanya lihat data bidangnya sendiri
        //     $query->where('bidang', $user->getBidang());
        // } elseif ($request->filled('bidang') && $user->isAdmin()) {
        //     // Admin bisa filter by bidang
        //     $query->where('bidang', $request->bidang);
        // }

        // ── Search ──────────────────────────────────────────────────────────
        // if ($request->filled('search')) {
        //     $q = $request->search;
        //     $query->where(function ($q2) use ($q) {
        //         $q2->where('kegiatan', 'like', "%{$q}%")
        //            ->orWhere('sub_kegiatan', 'like', "%{$q}%")
        //            ->orWhere('program', 'like', "%{$q}%")
        //            ->orWhere('sasaran_strategis', 'like', "%{$q}%")
        //            ->orWhere('indikator_kinerja', 'like', "%{$q}%");
        //     });
        // }

        // ── Tahun Filter ────────────────────────────────────────────────────
        // if ($request->filled('tahun')) {
        //     $query->where('tahun', $request->tahun);
        // }

        $kegiatan = $query
            ->orderBy('bidang')
            ->orderBy('kegiatan')
            ->paginate($request->get('per_page', 20));

        // Tambah computed fields
        $kegiatan->getCollection()->transform(function ($item) use ($user) {
            $item->total_realisasi_fisik    = $item->total_realisasi_fisik;
            $item->total_realisasi_anggaran = $item->total_realisasi_anggaran;
            $item->persen_target            = $item->persen_target;
            $item->persen_anggaran          = $item->persen_anggaran;
            $item->sisa_target              = $item->sisa_target;
            $item->sisa_anggaran            = $item->sisa_anggaran;

            // 🔥 Tambahan penting
            $item->can_manage = 
                $user->isAdmin() ||
                $user->canManageKegiatan($item);

            return $item;
        });

        return response()->json([
            'success' => true,
            'data'    => $kegiatan,
        ]);
    }

    /**
     * GET /api/kegiatan/{id}
     *
     * Detail kegiatan beserta semua realisasi per bulan.
     * Semua role bisa lihat detail.
     */
    public function show(int $id, Request $request): JsonResponse
    {
        $user     = $request->user();
        $kegiatan = Kegiatan::with([
            'realisasiFisik',
            'realisasiAnggaran',
            'keteranganKegiatan',
            'buktiKegiatan',
        ])->findOrFail($id);

        // Detail kegiatan bersifat read-only, jadi semua role yang login boleh melihat.
        // Hak input/update tetap dikirim lewat can_manage.

        return response()->json([
            'success' => true,
            'data' => array_merge($kegiatan->toArray(), [
                'total_realisasi_fisik'    => $kegiatan->total_realisasi_fisik,
                'total_realisasi_anggaran' => $kegiatan->total_realisasi_anggaran,
                'persen_target'            => $kegiatan->persen_target,
                'persen_anggaran'          => $kegiatan->persen_anggaran,
                'sisa_target'              => $kegiatan->sisa_target,
                'sisa_anggaran'            => $kegiatan->sisa_anggaran,
                'can_manage'               => $user->canManageKegiatan($kegiatan),
            ]),
        ]);
    }

    /**
     * POST /api/kegiatan
     * Admin saja yang bisa membuat kegiatan baru.
     * (Middleware: role:Admin)
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'sasaran_strategis' => 'required|string|max:255',
            'indikator_kinerja' => 'required|string|max:255',
            'satuan'            => 'required|string|max:50',
            'target'            => 'required|numeric|min:0',
            'tahun'             => 'required|digits:4|integer|min:2020|max:2099',
            'bidang'            => 'required|string|max:100',
            'program'           => 'required|string|max:255',
            'kegiatan'          => 'required|string|max:255',
            'sub_kegiatan'      => 'required|string|max:255',
            'pagu_anggaran'     => 'required|numeric|min:0',
        ]);

        $kegiatan = Kegiatan::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Kegiatan berhasil ditambahkan.',
            'data'    => $kegiatan,
        ], 201);
    }

    /**
     * PUT /api/kegiatan/{id}
     * Admin: bisa edit semua.
     * Staff bidang: hanya bisa edit kegiatan di bidangnya (via middleware).
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $kegiatan = Kegiatan::findOrFail($id);

        $validated = $request->validate([
            'sasaran_strategis' => 'sometimes|string|max:255',
            'indikator_kinerja' => 'sometimes|string|max:255',
            'satuan'            => 'sometimes|string|max:50',
            'target'            => 'sometimes|numeric|min:0',
            'tahun'             => 'sometimes|digits:4|integer|min:2020|max:2099',
            'bidang'            => 'sometimes|string|max:100',
            'program'           => 'sometimes|string|max:255',
            'kegiatan'          => 'sometimes|string|max:255',
            'sub_kegiatan'      => 'sometimes|string|max:255',
            'pagu_anggaran'     => 'sometimes|numeric|min:0',
        ]);

        $kegiatan->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Kegiatan berhasil diperbarui.',
            'data'    => $kegiatan,
        ]);
    }

    /**
     * DELETE /api/kegiatan/{id}
     * Admin saja.
     */
    public function destroy(int $id): JsonResponse
    {
        $kegiatan = Kegiatan::findOrFail($id);
        $kegiatan->delete();

        return response()->json([
            'success' => true,
            'message' => 'Kegiatan berhasil dihapus.',
        ]);
    }

    /**
     * GET /api/dashboard/summary
     * Ringkasan untuk halaman dashboard.
     */
    public function dashboardSummary(Request $request): JsonResponse
    {
        // $user  = $request->user();
        // $tahun = $request->input('tahun', date('Y'));

        // $query = Kegiatan::where('tahun', $tahun);

        // // Staff bidang hanya lihat ringkasan bidangnya
        // if ($user->isStaffBidang()) {
        //     $query->where('bidang', $user->getBidang());
        // }

        $tahun = $request->input('tahun', date('Y'));

        $kegiatan = Kegiatan::where('tahun', $tahun)->get();

        $totalTarget      = $kegiatan->sum('target');
        $totalPagu      = $kegiatan->sum('pagu_anggaran');
        $totalRealisasi = $kegiatan->sum(fn($k) => $k->total_realisasi_anggaran);
        $totalRealisasiFisik = $kegiatan->sum(fn($k) => $k->total_realisasi_fisik);
        $avgFisik       = $kegiatan->count()
            ? round($kegiatan->avg(fn($k) => $k->total_realisasi_fisik), 2)
            : 0;

        // Progress per bidang (admin/kadis/sekretaris lihat semua bidang)
        $bidangProgress = $kegiatan
            ->groupBy('bidang')
            ->map(function ($items, $bidang) {

                $totalTarget = $items->sum('target');
                $totalRealisasiFisik = $items->sum('total_realisasi_fisik');

                $progress = $totalTarget > 0
                    ? round(($totalRealisasiFisik / $totalTarget) * 100, 2)
                    : 0;

                return [
                    'nama' => $bidang,
                    'progress' => $progress,

                    // ✅ TAMBAHAN (ini yang kamu butuh di Flutter)
                    'total_target' => $totalTarget,
                    'total_realisasi_fisik' => $totalRealisasiFisik,

                    'count' => $items->count(),
                ];
            })
            ->values();

        return response()->json([
            'success' => true,
            'data' => [
                'tahun'                    => (int) $tahun,
                'total_kegiatan'           => $kegiatan->count(),
                'total_target'             => $totalTarget,
                'total_pagu_anggaran'      => $totalPagu,
                'total_realisasi_anggaran' => $totalRealisasi,
                'total_realisasi_fisik'    => $totalRealisasiFisik,
                'persen_anggaran'          => $totalPagu > 0
                    ? round($totalRealisasi / $totalPagu * 100, 2)
                    : 0,
                'rata_realisasi_fisik'     => $avgFisik,
                'bidang_progress'          => $bidangProgress,
            ],
        ]);
    }
}
