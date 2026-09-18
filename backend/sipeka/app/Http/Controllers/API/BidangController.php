<?php
// app/Http/Controllers/API/BidangController.php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Bidang;
use App\Models\BuktiKegiatan;
use App\Models\Kegiatan;
use App\Models\Undangan;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class BidangController extends Controller
{
    /**
     * GET /api/bidang
     *
     * Semua role yang login boleh melihat daftar bidang — dipakai untuk
     * dropdown/filter di banyak fitur (kegiatan, undangan, export, dst).
     * Ikut disertakan info akun staff utama (username saja, tanpa
     * password — password sudah otomatis disembunyikan lewat $hidden
     * di model User) supaya form di menu "Kelola Bidang" bisa auto-isi.
     */
    public function index(): JsonResponse
    {
        $bidang = Bidang::with('user:id,username,bidang_id')
            ->orderBy('nama')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $bidang,
        ]);
    }

    /**
     * POST /api/bidang
     * Admin saja.
     *
     * username & password bersifat OPSIONAL — kalau diisi, langsung
     * membuat akun login staff utama untuk bidang ini.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nama'       => 'required|string|max:100|unique:bidang,nama',
            'keterangan' => 'nullable|string|max:255',
            'username'   => 'nullable|string|max:50|unique:users,username',
            'password'   => 'nullable|string|min:6',
        ]);

        if (!empty($validated['username']) && empty($validated['password'])) {
            return response()->json([
                'success' => false,
                'message' => 'Kata sandi wajib diisi untuk membuat akun staff baru.',
            ], 422);
        }

        $bidang = DB::transaction(function () use ($validated) {
            $bidang = Bidang::create([
                'nama'       => $validated['nama'],
                'keterangan' => $validated['keterangan'] ?? null,
            ]);

            if (!empty($validated['username'])) {
                User::create([
                    'username'  => $validated['username'],
                    'password'  => Hash::make($validated['password']),
                    'role'      => $bidang->nama,
                    'bidang_id' => $bidang->id,
                ]);
            }

            return $bidang;
        });

        return response()->json([
            'success' => true,
            'message' => 'Bidang berhasil ditambahkan.',
            'data'    => $bidang->load('user:id,username,bidang_id'),
        ], 201);
    }

    /**
     * PUT /api/bidang/{id}
     * Admin saja.
     *
     * Kalau nama bidang berubah, otomatis disinkronkan ke:
     *   - kegiatan.bidang
     *   - undangan.bidang_terkait (token comma-separated)
     *   - role akun staff utama (label saja, akses tetap lewat bidang_id)
     *
     * username & password akun staff utama juga bisa diubah dari sini:
     *   - Kalau bidang belum punya akun & username diisi → akun baru dibuat
     *     (password wajib diisi untuk kasus ini).
     *   - Kalau bidang sudah punya akun → username/password yang diisi
     *     akan menimpa yang lama; kosongkan password kalau tidak ingin
     *     menggantinya.
     *
     * CATATAN PENTING: nama bidang yang masih dipakai sebagai pemetaan
     * role staff STRUKTURAL LAMA (App\Models\User::BIDANG_ROLE_MAP —
     * Kepala Bidang X, Kepala Sub Bagian Y, dst) TIDAK BOLEH diubah
     * namanya di sini, karena pemetaan tersebut hardcoded di kode
     * (bukan di database) sehingga rename di sini tidak ikut mengubahnya.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $bidang = Bidang::findOrFail($id);
        $existingUser = User::where('bidang_id', $bidang->id)->first();

        $validated = $request->validate([
            'nama'       => 'sometimes|required|string|max:100|unique:bidang,nama,' . $bidang->id,
            'keterangan' => 'nullable|string|max:255',
            'username'   => [
                'nullable',
                'string',
                'max:50',
                Rule::unique('users', 'username')->ignore($existingUser?->id),
            ],
            'password'   => 'nullable|string|min:6',
        ]);

        if (!empty($validated['username']) && empty($validated['password']) && $existingUser === null) {
            return response()->json([
                'success' => false,
                'message' => 'Kata sandi wajib diisi untuk membuat akun staff baru.',
            ], 422);
        }

        $namaLama    = $bidang->nama;
        $namaBaru    = $validated['nama'] ?? $namaLama;
        $namaBerubah = $namaBaru !== $namaLama;

        if ($namaBerubah && $this->dipakaiPemetaanRoleLama($namaLama)) {
            return response()->json([
                'success' => false,
                'message' => "Nama bidang \"{$namaLama}\" tidak dapat diubah karena masih dipakai sebagai pemetaan role staff struktural lama (akun login Kepala Bidang/Kepala Sub Bagian terkait). Hubungi developer untuk memperbarui pemetaan role terlebih dahulu jika nama ini benar-benar perlu diganti.",
            ], 422);
        }

        DB::transaction(function () use ($bidang, $validated, $namaLama, $namaBaru, $namaBerubah, $existingUser) {
            $bidang->update([
                'nama'       => $namaBaru,
                'keterangan' => array_key_exists('keterangan', $validated)
                    ? $validated['keterangan']
                    : $bidang->keterangan,
            ]);

            if ($namaBerubah) {
                // PENTING: pakai $namaLama yang ditangkap SEBELUM update()
                // dipanggil — setelah update(), Eloquent sudah menyamakan
                // "original" attribute ke nilai baru, jadi getOriginal()
                // di titik ini tidak bisa lagi dipakai untuk ambil nilai lama.
                Kegiatan::where('bidang', $namaLama)->update(['bidang' => $namaBaru]);
                $this->renameBidangDiUndangan($namaLama, $namaBaru);
            }

            // ── Sinkron akun staff utama bidang ini ──────────────────────
            if ($existingUser) {
                $changed = false;

                if (!empty($validated['username']) && $validated['username'] !== $existingUser->username) {
                    $existingUser->username = $validated['username'];
                    $changed = true;
                }
                if (!empty($validated['password'])) {
                    $existingUser->password = Hash::make($validated['password']);
                    $changed = true;
                }
                if ($namaBerubah) {
                    $existingUser->role = $namaBaru;
                    $changed = true;
                }
                if ($changed) {
                    $existingUser->save();
                }
            } elseif (!empty($validated['username'])) {
                User::create([
                    'username'  => $validated['username'],
                    'password'  => Hash::make($validated['password']),
                    'role'      => $bidang->nama,
                    'bidang_id' => $bidang->id,
                ]);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Bidang berhasil diperbarui.',
            'data'    => $bidang->fresh()->load('user:id,username,bidang_id'),
        ]);
    }

    /**
     * DELETE /api/bidang/{id}
     * Admin saja.
     *
     * Bidang SELALU boleh dihapus (Flutter sudah memastikan admin
     * mengonfirmasi 2 kali sebelum request ini dikirim). Menghapus bidang
     * akan ikut menghapus secara permanen:
     *   1. Semua Kegiatan pada bidang ini (+ file bukti fisiknya). Tabel
     *      realisasi_fisik, realisasi_anggaran, keterangan_kegiatan, dan
     *      bukti_kegiatan otomatis ikut terhapus lewat FK cascade di DB.
     *   2. Semua Undangan yang menyertakan bidang ini sebagai pihak
     *      terkait (+ file bukti kehadirannya).
     *   3. Akun staff utama bidang ini (kalau ada), termasuk token login
     *      aktifnya.
     */
    public function destroy(int $id): JsonResponse
    {
        $bidang = Bidang::findOrFail($id);

        DB::transaction(function () use ($bidang) {
            // 1) Kegiatan + file bukti fisiknya
            $kegiatanIds = Kegiatan::where('bidang', $bidang->nama)->pluck('id');

            if ($kegiatanIds->isNotEmpty()) {
                $buktiFiles = BuktiKegiatan::whereIn('kegiatan_id', $kegiatanIds)->pluck('file_path');
                foreach ($buktiFiles as $path) {
                    if ($path && Storage::disk('public')->exists($path)) {
                        Storage::disk('public')->delete($path);
                    }
                }
                Kegiatan::whereIn('id', $kegiatanIds)->delete();
            }

            // 2) Undangan yang menyertakan bidang ini + file buktinya
            $undanganTerkait = Undangan::where('bidang_terkait', 'like', "%{$bidang->nama}%")->get();
            foreach ($undanganTerkait as $u) {
                $tokens = array_map('trim', explode(',', $u->bidang_terkait ?? ''));
                if (in_array($bidang->nama, $tokens, true)) {
                    if ($u->bukti && Storage::disk('public')->exists($u->bukti)) {
                        Storage::disk('public')->delete($u->bukti);
                    }
                    $u->delete();
                }
            }

            // 3) Akun staff utama bidang ini (kalau ada)
            $user = User::where('bidang_id', $bidang->id)->first();
            if ($user) {
                $user->tokens()->delete();
                $user->delete();
            }

            // 4) Bidang itu sendiri
            $bidang->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Bidang beserta seluruh data kegiatan, undangan terkait, dan akun staff bidang berhasil dihapus.',
        ]);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /**
     * Cek apakah nama bidang tertentu masih dipakai di pemetaan
     * User::BIDANG_ROLE_MAP (role akun login jabatan struktural lama →
     * nama bidang). Hanya dipakai untuk memblokir RENAME, bukan hapus —
     * lihat catatan di method update().
     */
    private function dipakaiPemetaanRoleLama(string $namaBidang): bool
    {
        return in_array($namaBidang, array_unique(array_values(User::BIDANG_ROLE_MAP)), true);
    }

    /**
     * Ganti token nama bidang lama → baru di kolom bidang_terkait
     * (comma-separated) pada tabel undangan, tanpa mengubah token lain
     * yang tidak persis sama.
     */
    private function renameBidangDiUndangan(string $namaLama, string $namaBaru): void
    {
        $rows = Undangan::where('bidang_terkait', 'like', "%{$namaLama}%")->get();

        foreach ($rows as $row) {
            $items = array_map('trim', explode(',', $row->bidang_terkait ?? ''));
            $items = array_values(array_filter($items, fn ($x) => $x !== ''));

            $changed = false;
            $items = array_map(function ($item) use ($namaLama, $namaBaru, &$changed) {
                if ($item === $namaLama) {
                    $changed = true;
                    return $namaBaru;
                }
                return $item;
            }, $items);

            if ($changed) {
                $row->update(['bidang_terkait' => implode(', ', $items)]);
            }
        }
    }
}
