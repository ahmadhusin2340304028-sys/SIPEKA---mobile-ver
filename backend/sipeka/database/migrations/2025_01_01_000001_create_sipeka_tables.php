<?php
// ============================================================
// database/migrations/2025_01_01_000001_create_sipeka_tables.php
// ============================================================

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {

        // ── personal_access_tokens (Sanctum) ─────────────────────────────────
        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        // ── kegiatan ─────────────────────────────────────────────────────────
        Schema::create('kegiatan', function (Blueprint $table) {
            $table->id();
            $table->string('sasaran_strategis');
            $table->string('indikator_kinerja');
            $table->string('satuan', 50);
            $table->decimal('target', 10, 2);
            $table->year('tahun');
            $table->string('bidang', 100);
            $table->string('program');
            $table->string('kegiatan');
            $table->string('sub_kegiatan');
            $table->decimal('pagu_anggaran', 15, 2);
            $table->timestamps();

            $table->index(['tahun', 'bidang']);
        });

        // ── realisasi_fisik ───────────────────────────────────────────────────
        Schema::create('realisasi_fisik', function (Blueprint $table) {
            $table->id();
            $table->foreignId('kegiatan_id')
                  ->constrained('kegiatan')
                  ->onDelete('cascade');
            $table->tinyInteger('bulan')->unsigned();
            $table->decimal('nilai', 15, 2)->comment('Persentase 0-100');

            $table->unique(['kegiatan_id', 'bulan']);
            $table->index('kegiatan_id');
        });

        // ── realisasi_anggaran ────────────────────────────────────────────────
        Schema::create('realisasi_anggaran', function (Blueprint $table) {
            $table->id();
            $table->foreignId('kegiatan_id')
                  ->constrained('kegiatan')
                  ->onDelete('cascade');
            $table->tinyInteger('bulan')->unsigned();
            $table->decimal('nilai', 15, 2)->comment('Nominal rupiah');

            $table->unique(['kegiatan_id', 'bulan']);
            $table->index('kegiatan_id');
        });

        // ── keterangan_kegiatan ───────────────────────────────────────────────
        Schema::create('keterangan_kegiatan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('kegiatan_id')
                  ->constrained('kegiatan')
                  ->onDelete('cascade');
            $table->tinyInteger('bulan')->unsigned();
            $table->text('keterangan')->nullable();

            $table->unique(['kegiatan_id', 'bulan']);
            $table->index('kegiatan_id');
        });

        // ── bukti_kegiatan ────────────────────────────────────────────────────
        Schema::create('bukti_kegiatan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('kegiatan_id')
                  ->constrained('kegiatan')
                  ->onDelete('cascade');
            $table->tinyInteger('bulan')->unsigned();
            $table->string('file_path');

            $table->unique(['kegiatan_id', 'bulan']);
            $table->index('kegiatan_id');
        });

        // ── undangan ──────────────────────────────────────────────────────────
        Schema::create('undangan', function (Blueprint $table) {
            $table->id();
            $table->string('judul_kegiatan');
            $table->date('tanggal');
            $table->time('waktu');
            $table->string('tempat');
            $table->string('pihak_mengundang');
            $table->string('bidang_terkait', 150);
            $table->string('status_kegiatan', 50)->default('Belum Dilaksanakan');
            $table->string('menghadiri', 50)->default('Pending');
            $table->string('bukti')->nullable();
            $table->string('delegasi')->nullable();
            $table->timestamps();

            $table->index(['tanggal', 'bidang_terkait']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('undangan');
        Schema::dropIfExists('bukti_kegiatan');
        Schema::dropIfExists('keterangan_kegiatan');
        Schema::dropIfExists('realisasi_anggaran');
        Schema::dropIfExists('realisasi_fisik');
        Schema::dropIfExists('kegiatan');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('users');
    }
};
