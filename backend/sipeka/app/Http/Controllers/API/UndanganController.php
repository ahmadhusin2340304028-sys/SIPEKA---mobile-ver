<?php
// app/Http/Controllers/API/UndanganController.php — bagian store() method

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Undangan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class UndanganController extends Controller
{
    /**
     * POST /api/undangan
     *
     * Dari Flutter atau Web Form
     * bidang_terkait dikirim sebagai:
     * - Array dari Flutter: ['Kepala Dinas', 'Perencanaan dan Keuangan', ...]
     * - Comma-separated dari web form: 'Kepala Dinas, Perencanaan dan Keuangan, ...'
     *
     * Disimpan ke database sebagai: "Kepala Dinas, Perencanaan dan Keuangan, ..."
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
            
            // Support input dari Flutter (array) atau Web Form (string)
            'bidang_terkait'  => 'required',
        ]);

        // ── Parse bidang_terkait ──────────────────────────────────────────
        $bidangTerkait = $this->_parseBidangTerkait($validated['bidang_terkait']);

        if (empty($bidangTerkait)) {
            return response()->json([
                'success' => false,
                'message' => 'Pihak terkait/diundang wajib dipilih.',
            ], 422);
        }

        // ── Validasi untuk staff bidang ──────────────────────────────────
        if ($user->isStaffBidang()) {
            $userBidang = $user->getBidang();
            // Cek apakah bidang staff ada dalam string (substring match)
            if (!str_contains($bidangTerkait, $userBidang)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda hanya dapat membuat undangan yang menyertakan bidang Anda.',
                    'bidang_anda' => $userBidang,
                ], 403);
            }
        }

        // ── Buat record undangan ────────────────────────────────────────
        $undangan = Undangan::create([
            'judul_kegiatan'  => $validated['judul_kegiatan'],
            'tanggal'         => $validated['tanggal'],
            'waktu'           => $validated['waktu'],
            'tempat'          => $validated['tempat'],
            'pihak_mengundang' => $validated['pihak_mengundang'],
            'bidang_terkait'  => $bidangTerkait, // ← Comma-separated string
            'status_kegiatan' => Undangan::STATUS_BELUM,
            'menghadiri'      => Undangan::HADIR_PENDING,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil ditambahkan.',
            'data'    => $undangan,
        ], 201);
    }

    /**
     * GET /api/undangan
     *
     * Filter staff bidang dengan LIKE operator
     * Karena bidang_terkait adalah comma-separated string
     */
    public function index(Request $request): JsonResponse
    {
        $user  = $request->user();
        $query = Undangan::query();

        // Semua role yang login boleh melihat daftar undangan.
        // Hak konfirmasi hadir/tidak hadir tetap dicek di endpoint aksi.

        // Filter status kehadiran (opsional)
        if ($request->filled('status')) {
            $query->where('menghadiri', $request->status);
        }

        $undangan = $query
            ->orderByDesc('tanggal')
            ->paginate($request->get('per_page', 20));

        // Tambah field bukti_url
        $undangan->getCollection()->transform(function ($item) use ($user) {
            $item->bukti_url = $item->bukti_url;
            $item->can_respond = $this->canRespond($user, $item);
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

        // Detail bersifat read-only, jadi semua role yang login boleh melihat.

        return response()->json([
            'success' => true,
            'data'    => array_merge($undangan->toArray(), [
                'bukti_url' => $undangan->bukti_url,
                'can_respond' => $this->canRespond($user, $undangan),
            ]),
        ]);
    }

    /**
     * PUT /api/undangan/{id}
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user     = $request->user();
        $undangan = Undangan::findOrFail($id);

        if ($user->isStaffBidang()) {
            $bidang = $user->getBidang();
            if (!str_contains($undangan->bidang_terkait, $bidang)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak.',
                ], 403);
            }
        }

        $validated = $request->validate([
            'judul_kegiatan'  => 'sometimes|string|max:255',
            'tanggal'         => 'sometimes|date',
            'waktu'           => 'sometimes|date_format:H:i',
            'tempat'          => 'sometimes|string|max:255',
            'pihak_mengundang' => 'sometimes|string|max:255',
            'bidang_terkait'  => 'sometimes|string|max:1000',
            'status_kegiatan' => 'sometimes|string|max:50',
            'menghadiri'      => 'sometimes|string|in:Hadir,Tidak Hadir,Pending',
            'delegasi'        => 'nullable|string|max:500',
        ]);

        // Jika bidang_terkait diupdate, parse dulu
        if (isset($validated['bidang_terkait'])) {
            $validated['bidang_terkait'] = $this->_parseBidangTerkait($validated['bidang_terkait']);
        }

        $undangan->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil diperbarui.',
            'data'    => $undangan,
        ]);
    }

    /**
     * POST /api/undangan/{id}/kehadiran
     *
     * Update status kehadiran + upload bukti (opsional) + delegasi (opsional)
     * Field menghadiri diisi otomatis dari bidang/username user yang login.
     */
    public function updateKehadiran(Request $request, int $id): JsonResponse
    {
        $user     = $request->user();
        $undangan = Undangan::findOrFail($id);

        // Semua bidang/pihak boleh konfirmasi hadir.
        // bidang_terkait hanya dipakai sebagai informasi undangan.

        $validated = $request->validate([
            'delegasi' => 'nullable|string|max:500',
            'bukti'    => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        // Auto-fill menghadiri dari identitas user login
        $identitasMenghadiri = $user->getBidang() ?? $user->username;

        // Upload bukti jika ada
        if ($request->hasFile('bukti')) {
            if ($undangan->bukti && Storage::disk('public')->exists($undangan->bukti)) {
                Storage::disk('public')->delete($undangan->bukti);
            }
            $validated['bukti'] = $request->file('bukti')->store('bukti-undangan', 'public');
        }

        $undangan->update([
            'menghadiri'      => $identitasMenghadiri,
            'delegasi'        => $validated['delegasi'] ?? null,
            'bukti'           => $validated['bukti'] ?? $undangan->bukti,
            'status_kegiatan' => Undangan::STATUS_SELESAI,
        ]);

        return response()->json([
            'success' => true,
            'message' => "Kehadiran dikonfirmasi oleh {$identitasMenghadiri}.",
            'data'    => array_merge($undangan->fresh()->toArray(), [
                'bukti_url' => $undangan->fresh()->bukti_url,
            ]),
        ]);
    }

    /**
     * POST /api/undangan/{id}/tidak-hadir
     */
    public function tidakHadir(Request $request, int $id): JsonResponse
    {
        $user     = $request->user();
        $undangan = Undangan::findOrFail($id);

        // Semua bidang/pihak boleh menandai tidak hadir.

        $undangan->update([
            'menghadiri'      => 'Tidak Hadir',
            'status_kegiatan' => Undangan::STATUS_SELESAI,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Undangan ditandai sebagai Tidak Hadir.',
            'data'    => array_merge($undangan->fresh()->toArray(), [
                'bukti_url' => $undangan->fresh()->bukti_url,
            ]),
        ]);
    }

    /**
     * DELETE /api/undangan/{id}
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

    // ─── Helper ───────────────────────────────────────────────────────────

    /**
     * Parse bidang_terkait dari berbagai format:
     * - Array (dari Flutter): ['Kepala Dinas', 'Perencanaan dan Keuangan']
     * - String comma-separated: 'Kepala Dinas, Perencanaan dan Keuangan'
     *
     * Selalu return: "Kepala Dinas, Perencanaan dan Keuangan"
     */
    private function _parseBidangTerkait($input): string
    {
        if (is_array($input)) {
            // Dari Flutter: array
            $cleaned = array_map('trim', $input);
            $cleaned = array_filter($cleaned, fn($x) => !empty($x));
            return implode(', ', $cleaned);
        }

        // Dari web form: string
        $str = trim((string)$input);
        if (empty($str)) return '';

        // Jika sudah comma-separated, cleanup spaces
        $items = array_map('trim', explode(',', $str));
        $items = array_filter($items, fn($x) => !empty($x));
        return implode(', ', $items);
    }

    private function canRespond($user, Undangan $undangan): bool
    {
        return true;
    }
}
