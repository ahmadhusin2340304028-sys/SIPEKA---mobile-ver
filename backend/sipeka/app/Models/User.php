<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    protected $table = 'users';

    protected $fillable = [
        'username',
        'password',
        'role',
        'bidang_id',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    // ─── Role Constants ───────────────────────────────────────────────────────

    const ROLE_ADMIN        = 'Admin';
    const ROLE_KADIS        = 'Kepala Dinas';
    const ROLE_SEKRETARIS   = 'Sekretaris';

    /**
     * Bidang-based staff roles — hanya bisa kelola data sesuai bidangnya.
     * Key = role string di DB, Value = nilai bidang di tabel kegiatan.
     *
     * CATATAN (sejak fitur "Kelola Bidang" dengan akun staff terintegrasi):
     * akun staff UTAMA tiap bidang sekarang terhubung lewat kolom
     * users.bidang_id (lihat relasi bidang() & getBidang() di bawah) dan
     * dikelola langsung dari menu "Kelola Bidang" — TIDAK lagi lewat peta
     * ini. Peta ini tetap dipertahankan sebagai FALLBACK khusus untuk akun
     * jabatan struktural yang belum dikelola lewat menu tsb (Kepala Dinas,
     * Sekretaris, Kepala Bidang X, Kepala Sub Bagian Y) — di luar cakupan
     * fitur Kelola Bidang saat ini.
     */
    const BIDANG_ROLE_MAP = [
        'Admin'                                 => 'Admin', // Admin bisa akses semua bidang   
        'Kepala Dinas'                          => 'Kepala Dinas', // Kadis bisa akses semua bidang
        'Sekretaris'                            => 'Sekretaris', // Sekretaris bisa akses semua bidang
        'Perencanaan dan Keuangan'              => 'Perencanaan dan Keuangan',
        'Umum dan Kepegawaian'                  => 'Umum dan Kepegawaian',
        'Rehabilitasi Sosial'                   => 'Rehabilitasi Sosial',
        'Perlindungan dan Jaminan Sosial'       => 'Perlindungan dan Jaminan Sosial',
        'Pemberdayaan Sosial'                   => 'Pemberdayaan Sosial',
        'Pemberdayaan Masyarakat'               => 'Pemberdayaan Masyarakat',
        'Kepala Bidang Sosial'                  => 'Rehabilitasi Sosial',
        'Kepala Bidang Pemberdayaan Masyarakat' => 'Pemberdayaan Masyarakat',
        'Kepala Sub Bagian Perencanaan'         => 'Perencanaan dan Keuangan',
        'Kepala Sub Bagian Kepegawaian'         => 'Umum dan Kepegawaian',
    ];

    // ─── Role Checks ──────────────────────────────────────────────────────────

    public function isAdmin(): bool
    {
        return $this->role === self::ROLE_ADMIN;
    }

    public function isKadis(): bool
    {
        return $this->role === self::ROLE_KADIS;
    }

    public function isSekretaris(): bool
    {
        return $this->role === self::ROLE_SEKRETARIS;
    }

    /**
     * Admin/Kadis/Sekretaris boleh melihat semua data.
     * Kadis dan Sekretaris tetap view-only untuk endpoint write.
     */
    public function canViewAll(): bool
    {
        return $this->isAdmin() || $this->isKadis() || $this->isSekretaris();
    }

    /**
     * Apakah user adalah staff bidang (bukan admin/kadis/sekretaris).
     * Diprioritaskan dari relasi bidang_id (dikelola lewat menu "Kelola
     * Bidang"), fallback ke peta role lama untuk akun jabatan struktural
     * yang belum dikelola lewat menu tsb.
     */
    public function isStaffBidang(): bool
    {
        if ($this->canViewAll()) {
            return false;
        }

        if ($this->bidang_id !== null) {
            return true;
        }

        return array_key_exists($this->role, self::BIDANG_ROLE_MAP);
    }

    /**
     * Mendapatkan nama bidang yang menjadi tanggung jawab user ini.
     * Return null jika bukan staff bidang.
     */
    public function getBidang(): ?string
    {
        if ($this->canViewAll()) {
            return null;
        }

        // Sumber utama: relasi ke tabel bidang (dikelola lewat "Kelola Bidang").
        if ($this->bidang_id !== null) {
            return $this->bidang?->nama;
        }

        // Fallback: akun jabatan struktural lama, masih pakai peta hardcoded.
        return self::BIDANG_ROLE_MAP[$this->role] ?? null;
    }

    /**
     * Apakah user boleh mengelola (create/update/delete) kegiatan tertentu?
     */
    public function canManageKegiatan(Kegiatan $kegiatan): bool
    {
        if ($this->isAdmin()) return true;
        if ($this->canViewAll()) return false;

        $bidang = $this->getBidang();
        if ($bidang === null) return false; // kadis/sekretaris = view only

        return $kegiatan->bidang === $bidang;
    }

    // ─── Relationships ────────────────────────────────────────────────────────

    /**
     * Bidang yang menjadi tanggung jawab utama akun ini (kalau ada).
     * Dikelola langsung lewat form akun staff di menu "Kelola Bidang".
     */
    public function bidang(): BelongsTo
    {
        return $this->belongsTo(Bidang::class, 'bidang_id');
    }

    public function realisasiFisik(): HasMany
    {
        return $this->hasMany(RealisasiFisik::class);
    }

    public function realisasiAnggaran(): HasMany
    {
        return $this->hasMany(RealisasiAnggaran::class);
    }
}
