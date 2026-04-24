<?php
// app/Models/KeteranganKegiatan.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class KeteranganKegiatan extends Model
{
    protected $table = 'keterangan_kegiatan';

    protected $fillable = [
        'kegiatan_id',
        'bulan',
        'keterangan',
    ];

    protected $casts = [
        'bulan' => 'integer',
    ];

    public $timestamps = false;

    public function kegiatan(): BelongsTo
    {
        return $this->belongsTo(Kegiatan::class, 'kegiatan_id');
    }
}
