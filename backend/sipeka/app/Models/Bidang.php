<?php
// app/Models/Bidang.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Bidang extends Model
{
    protected $table = 'bidang';

    protected $fillable = [
        'nama',
        'keterangan',
    ];

    /**
     * Akun staff utama yang terhubung ke bidang ini (kalau ada).
     * Dikelola langsung lewat form di menu "Kelola Bidang".
     */
    public function user(): HasOne
    {
        return $this->hasOne(User::class, 'bidang_id');
    }
}
