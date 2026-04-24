<?php
// app/Models/RealisasiFisik.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RealisasiFisik extends Model
{
    protected $table = 'realisasi_fisik';

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
