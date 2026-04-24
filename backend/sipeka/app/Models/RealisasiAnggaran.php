<?php
// app/Models/RealisasiAnggaran.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RealisasiAnggaran extends Model
{
    protected $table = 'realisasi_anggaran';

    protected $fillable = [
        'kegiatan_id',
        'bulan',
        'nilai',
    ];

    protected $casts = [
        'nilai' => 'decimal:2',
        'bulan' => 'integer',
    ];

    public $timestamps = false;

    public function kegiatan(): BelongsTo
    {
        return $this->belongsTo(Kegiatan::class, 'kegiatan_id');
    }
}
