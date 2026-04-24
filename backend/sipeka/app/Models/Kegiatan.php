<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Kegiatan extends Model
{
    protected $table = 'kegiatan';

    protected $fillable = [
        'sasaran_strategis',
        'indikator_kinerja',
        'satuan',
        'target',
        'tahun',
        'bidang',
        'program',
        'kegiatan',
        'sub_kegiatan',
        'pagu_anggaran',
    ];

    protected $casts = [
        'target'        => 'float',   // ✅ ganti dari 'decimal:2'
        'pagu_anggaran' => 'float',   // ✅ ganti dari 'decimal:2'
        'tahun'         => 'integer',
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
    ];

    // ─── Relationships ────────────────────────────────────────────────────────

    public function realisasiFisik(): HasMany
    {
        return $this->hasMany(RealisasiFisik::class, 'kegiatan_id');
    }

    public function realisasiAnggaran(): HasMany
    {
        return $this->hasMany(RealisasiAnggaran::class, 'kegiatan_id');
    }

    public function keteranganKegiatan(): HasMany
    {
        return $this->hasMany(KeteranganKegiatan::class, 'kegiatan_id');
    }

    public function buktiKegiatan(): HasMany
    {
        return $this->hasMany(BuktiKegiatan::class, 'kegiatan_id');
    }

    // ─── Computed Attributes ──────────────────────────────────────────────────

    /**
     * Total realisasi fisik kumulatif (bulan terakhir yang diisi).
     */
    public function getTotalRealisasiFisikAttribute(): float
    {
        return (float) $this->realisasiFisik()->sum('nilai') ?? 0;
    }

    /**
     * Total realisasi anggaran (sum semua bulan).
     */
    public function getTotalRealisasiAnggaranAttribute(): float
    {
        return (float) $this->realisasiAnggaran()->sum('nilai') ?? 0;
    }

    /**
     * Persentase target.
     */
    public function getPersenTargetAttribute(): float
    {
        if ($this->target <= 0) return 0;
        return round($this->total_realisasi_fisik / $this->target * 100, 2);
    }

    /**
     * Persentase serapan anggaran.
     */
    public function getPersenAnggaranAttribute(): float
    {
        if ($this->pagu_anggaran <= 0) return 0;
        return round($this->total_realisasi_anggaran / $this->pagu_anggaran * 100, 2);
    }

    /**
     * Sisa anggaran.
     */
    public function getSisaTargetAttribute(): float
    {
        return (float) $this->target - $this->total_realisasi_fisik;
    }

    /**
     * Sisa anggaran.
     */
    public function getSisaAnggaranAttribute(): float
    {
        return (float) $this->pagu_anggaran - $this->total_realisasi_anggaran;
    }
}
