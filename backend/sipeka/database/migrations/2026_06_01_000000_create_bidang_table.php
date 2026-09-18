<?php
// database/migrations/2026_06_01_000000_create_bidang_table.php
//
// Membuat master data "bidang" yang akan dikelola Admin lewat menu
// "Kelola Bidang", dan dipakai sebagai sumber data untuk semua fitur lain
// yang butuh daftar bidang (dropdown input Kegiatan, filter Kegiatan,
// checklist pihak diundang Undangan, filter Export, dst).

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Daftar bidang default — sesuai data kegiatan yang sudah berjalan
     * saat ini (lihat App\Models\User::BIDANG_ROLE_MAP). Di-seed langsung
     * di migration (bukan hanya di seeder) supaya begitu migration ini
     * dijalankan di server produksi yang sudah punya data kegiatan,
     * seluruh kegiatan yang ada tetap konsisten dengan tabel bidang baru.
     */
    private const DEFAULT_BIDANG = [
        'Perencanaan dan Keuangan',
        'Umum dan Kepegawaian',
        'Rehabilitasi Sosial',
        'Perlindungan dan Jaminan Sosial',
        'Pemberdayaan Sosial',
        'Pemberdayaan Masyarakat',
    ];

    public function up(): void
    {
        Schema::create('bidang', function (Blueprint $table) {
            $table->id();
            $table->string('nama', 100)->unique();
            $table->string('keterangan', 255)->nullable();
            $table->timestamps();
        });

        $now = now();

        // 1) Seed bidang default
        foreach (self::DEFAULT_BIDANG as $nama) {
            DB::table('bidang')->updateOrInsert(
                ['nama' => $nama],
                ['created_at' => $now, 'updated_at' => $now]
            );
        }

        // 2) Safety net: kalau di tabel kegiatan sudah ada nilai bidang lain
        //    (misalnya data custom yang pernah diinput manual di server
        //    produksi) yang belum ada di daftar default di atas, ikut
        //    dimasukkan juga. Ini mencegah ada kegiatan yang "kehilangan"
        //    bidangnya / gagal validasi setelah fitur ini aktif.
        if (Schema::hasTable('kegiatan')) {
            $existingBidang = DB::table('kegiatan')
                ->whereNotNull('bidang')
                ->where('bidang', '!=', '')
                ->distinct()
                ->pluck('bidang');

            foreach ($existingBidang as $nama) {
                DB::table('bidang')->updateOrInsert(
                    ['nama' => $nama],
                    ['created_at' => $now, 'updated_at' => $now]
                );
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('bidang');
    }
};
