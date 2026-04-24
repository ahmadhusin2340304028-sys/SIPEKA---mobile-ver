<?php
// routes/api.php

use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\KegiatanController;
use App\Http\Controllers\API\RealisasiController;
use App\Http\Controllers\API\UndanganController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| SIPEKA API Routes
|--------------------------------------------------------------------------
|
| Middleware yang digunakan:
|   auth:sanctum     → wajib login (Bearer token)
|   role:X,Y         → hanya role tertentu
|   bidang.access    → staff hanya kelola data bidangnya sendiri
|
*/

// ─── PUBLIC ───────────────────────────────────────────────────────────────────

Route::post('/login', [AuthController::class, 'login']);

// ─── AUTHENTICATED ────────────────────────────────────────────────────────────

Route::middleware('auth:sanctum')->group(function () {

    // ── Auth ──────────────────────────────────────────────────────────────────
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user',    [AuthController::class, 'me']);

    // ── Dashboard ─────────────────────────────────────────────────────────────
    // Semua role bisa akses dashboard, tapi data difilter per bidang di controller
    Route::get('/dashboard/summary', [KegiatanController::class, 'dashboardSummary']);

    // ── Kegiatan ──────────────────────────────────────────────────────────────
    Route::prefix('kegiatan')->group(function () {

        // READ → semua role bisa lihat (data difilter per bidang di controller)
        Route::get('/',    [KegiatanController::class, 'index']);
        Route::get('/{id}', [KegiatanController::class, 'show'])->where('id', '[0-9]+');

        // Realisasi per kegiatan (READ) → semua role
        Route::get('/{id}/realisasi', [RealisasiController::class, 'index'])->where('id', '[0-9]+');

        // WRITE → admin bisa semua, staff hanya bidangnya (via bidang.access)
        Route::middleware('bidang.access')->group(function () {

            // Admin saja bisa create/delete kegiatan master
            Route::post('/',       [KegiatanController::class, 'store'])
                ->middleware('role:Admin');

            Route::put('/{id}',    [KegiatanController::class, 'update'])
                ->where('id', '[0-9]+');

            Route::delete('/{id}', [KegiatanController::class, 'destroy'])
                ->where('id', '[0-9]+')
                ->middleware('role:Admin');
        });
    });

    // ── Realisasi (input fisik + anggaran) ────────────────────────────────────
    // Staff bidang + admin bisa input; kadis/sekretaris = view only
    Route::middleware('bidang.access')->group(function () {
        Route::post('/realisasi', [RealisasiController::class, 'store']);

        Route::delete(
            '/realisasi/{kegiatan_id}/{bulan}',
            [RealisasiController::class, 'destroy']
        )->where(['kegiatan_id' => '[0-9]+', 'bulan' => '[0-9]+'])
         ->middleware('role:Admin');
    });

    // ── Upload Bukti Kegiatan ─────────────────────────────────────────────────
    Route::post('/upload-bukti', [RealisasiController::class, 'uploadBukti'])
        ->middleware('bidang.access');

    // ── Undangan ──────────────────────────────────────────────────────────────
    Route::prefix('undangan')->group(function () {

        // READ → semua role, data difilter per bidang di controller
        Route::get('/',    [UndanganController::class, 'index']);
        Route::get('/{id}', [UndanganController::class, 'show'])->where('id', '[0-9]+');

        // WRITE → admin + staff bidang
        Route::middleware('bidang.access')->group(function () {

            Route::post('/',       [UndanganController::class, 'store']);

            Route::put('/{id}',    [UndanganController::class, 'update'])
                ->where('id', '[0-9]+');

            // Update kehadiran (staff bisa lakukan untuk undangan bidangnya)
            Route::post('/{id}/kehadiran', [UndanganController::class, 'updateKehadiran'])
                ->where('id', '[0-9]+');

            // Hapus hanya admin
            Route::delete('/{id}', [UndanganController::class, 'destroy'])
                ->where('id', '[0-9]+')
                ->middleware('role:Admin');
        });
    });
});
