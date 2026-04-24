<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
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
     * Apakah user adalah staff bidang (bukan admin/kadis/sekretaris).
     */
    public function isStaffBidang(): bool
    {
        return array_key_exists($this->role, self::BIDANG_ROLE_MAP);
    }

    /**
     * Mendapatkan nama bidang yang menjadi tanggung jawab user ini.
     * Return null jika bukan staff bidang.
     */
    public function getBidang(): ?string
    {
        return self::BIDANG_ROLE_MAP[$this->role] ?? null;
    }

    /**
     * Apakah user boleh mengelola (create/update/delete) kegiatan tertentu?
     */
    public function canManageKegiatan(Kegiatan $kegiatan): bool
    {
        if ($this->isAdmin()) return true;

        $bidang = $this->getBidang();
        if ($bidang === null) return false; // kadis/sekretaris = view only

        return $kegiatan->bidang === $bidang;
    }

    // ─── Relationships ────────────────────────────────────────────────────────

    public function realisasiFisik(): HasMany
    {
        return $this->hasMany(RealisasiFisik::class);
    }

    public function realisasiAnggaran(): HasMany
    {
        return $this->hasMany(RealisasiAnggaran::class);
    }
}
