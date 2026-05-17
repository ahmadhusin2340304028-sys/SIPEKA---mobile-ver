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
     * POST /api/undangan
     *
     * Admin membuat undangan baru.
     * bidang_terkait dikirim sebagai array dari Flutter:
     *   ['Kepala Dinas', 'Perencanaan dan Keuangan', ...]
     * Disimpan ke DB sebagai comma-separated string.
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'judul_kegiatan'   => 'required|string|max:255',
            'tanggal'          => 'required|date',
            'waktu'            => 'required|date_format:H:i',
            'tempat'           => 'required|string|max:255',
            'pihak_mengundang' => 'required|string|max:255',
            'bidang_terkait'   => 'required',   // bisa array atau string
        ]);

        $bidangTerkait = $this->_parseBidangTerkait($validated['bidang_terkait']);

        if (empty($bidangTerkait)) {
            return response()->json([
                'success' => false,
                'message' => 'Pihak terkait/diundang wajib dipilih.',
            ], 422);
        }

        // Staff bidang: harus menyertakan bidangnya sendiri
        if ($user->isStaffBidang()) {
            $userBidang = $user->getBidang();
            if (!str_contains($bidangTerkait, $userBidang)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda hanya dapat membuat undangan yang menyertakan bidang Anda.',
                    'bidang_anda' => $userBidang,
                ], 403);
            }
        }

        $undangan = Undangan::create([
            'judul_kegiatan'   => $validated['judul_kegiatan'],
            'tanggal'          => $validated['tanggal'],
            'waktu'            => $validated['waktu'],
            'tempat'           => $validated['tempat'],
            'pihak_mengundang' => $validated['pihak_mengundang'],
            'bidang_terkait'   => $bidangTerkait,
            'status_kegiatan'  => Undangan::HADIR_PENDING,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil ditambahkan.',
            'data'    => $undangan,
        ], 201);
    }

    /**
     * GET /api/undangan
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $baseQuery = Undangan::query();

        if ($request->filled('status')) {
            $status = strtolower(trim((string) $request->status));

            if ($status === 'pending') {
                $baseQuery->where('status_kegiatan', Undangan::HADIR_PENDING);
            } elseif (in_array($status, ['tidak_hadir', 'tidak hadir'], true)) {
                $baseQuery->where('menghadiri', Undangan::HADIR_TIDAK);
            } elseif ($status === 'hadir') {
                $baseQuery
                    ->whereNotNull('menghadiri')
                    ->whereNotIn('menghadiri', ['', Undangan::HADIR_PENDING, Undangan::HADIR_TIDAK]);
            }
        }

        $totalPending = (clone $baseQuery)
            ->where('status_kegiatan', 'Pending')
            ->count();

        $query = clone $baseQuery;

        if ($request->get('sort') === 'nearest') {
            $today = now()->toDateString();
            $query
                ->orderByRaw('CASE WHEN tanggal >= ? THEN 0 ELSE 1 END', [$today])
                ->orderBy('tanggal')
                ->orderBy('waktu');
        } else {
            $query->orderByDesc('tanggal');
        }

        $undangan = $query->paginate($request->get('per_page', 20));

        $undangan->getCollection()->transform(function ($item) use ($user) {
            $item->bukti_url   = $item->bukti_url;
            $item->can_respond = $this->canRespond($user, $item);
            return $item;
        });

        return response()->json([
            'success'       => true,
            'total_pending' => $totalPending,
            'data'          => $undangan,
        ]);
    }

    /**
     * GET /api/undangan/{id}
     */
    public function show(int $id, Request $request): JsonResponse
    {
        $user     = $request->user();
        $undangan = Undangan::findOrFail($id);

        return response()->json([
            'success' => true,
            'data'    => array_merge($undangan->toArray(), [
                'bukti_url'   => $undangan->bukti_url,
                'can_respond' => $this->canRespond($user, $undangan),
            ]),
        ]);
    }

    /**
     * PUT /api/undangan/{id}
     *
     * Admin hanya boleh update field yang dia isi saat create:
     *   judul_kegiatan, tanggal, waktu, tempat, pihak_mengundang, bidang_terkait
     *
     * Field menghadiri, bukti, delegasi adalah domain user — tidak diubah di sini.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user     = $request->user();
        $undangan = Undangan::findOrFail($id);

        // Staff bidang hanya boleh edit undangan yang menyertakan bidangnya
        if ($user->isStaffBidang()) {
            $bidang = $user->getBidang();
            if (!str_contains($undangan->bidang_terkait ?? '', $bidang)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Akses ditolak.',
                ], 403);
            }
        }

        // Validasi — bidang_terkait boleh array atau string
        $validated = $request->validate([
            'judul_kegiatan'   => 'sometimes|string|max:255',
            'tanggal'          => 'sometimes|date',
            'waktu'            => 'sometimes|date_format:H:i',
            'tempat'           => 'sometimes|string|max:255',
            'pihak_mengundang' => 'sometimes|string|max:255',
            'bidang_terkait'   => 'sometimes',  // ← terima array ATAU string
        ]);

        // Parse bidang_terkait jika dikirim
        if (array_key_exists('bidang_terkait', $validated)) {
            $parsed = $this->_parseBidangTerkait($validated['bidang_terkait']);
            if (empty($parsed)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pihak terkait/diundang wajib dipilih.',
                ], 422);
            }
            $validated['bidang_terkait'] = $parsed;
        }

        // Hanya update field yang dikirim (tidak sentuh menghadiri/bukti/delegasi)
        $updateData = array_filter(
            $validated,
            fn($key) => in_array($key, [
                'judul_kegiatan',
                'tanggal',
                'waktu',
                'tempat',
                'pihak_mengundang',
                'bidang_terkait',
            ]),
            ARRAY_FILTER_USE_KEY
        );

        $undangan->update($updateData);

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil diperbarui.',
            'data'    => $undangan->fresh(),
        ]);
    }

    /**
     * POST /api/undangan/{id}/kehadiran
     *
     * User mengonfirmasi hadir + upload bukti (opsional) + delegasi (opsional).
     * Field menghadiri diisi otomatis dari identitas user login.
     */
    public function updateKehadiran(Request $request, int $id): JsonResponse
    {
        $user     = $request->user();
        $undangan = Undangan::findOrFail($id);

        $validated = $request->validate([
            'delegasi' => 'nullable|string|max:500',
            'bukti'    => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        $identitasMenghadiri = $user->getBidang() ?? $user->username;

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
        $undangan = Undangan::findOrFail($id);

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

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /**
     * Parse bidang_terkait dari berbagai format ke comma-separated string.
     *
     * Input bisa:
     *   - Array (Flutter): ['Kepala Dinas', 'Perencanaan dan Keuangan']
     *   - String CSV: 'Kepala Dinas, Perencanaan dan Keuangan'
     *
     * Output: "Kepala Dinas, Perencanaan dan Keuangan"
     */
    private function _parseBidangTerkait($input): string
    {
        if (is_array($input)) {
            $cleaned = array_map('trim', $input);
            $cleaned = array_filter($cleaned, fn($x) => !empty($x));
            return implode(', ', array_values($cleaned));
        }

        $str = trim((string) $input);
        if (empty($str)) return '';

        $items = array_map('trim', explode(',', $str));
        $items = array_filter($items, fn($x) => !empty($x));
        return implode(', ', array_values($items));
    }

    private function canRespond($user, Undangan $undangan): bool
    {
        return true;
    }
}
