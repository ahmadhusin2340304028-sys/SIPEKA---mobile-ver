<?php
// database/migrations/2026_06_02_000000_add_bidang_id_to_users_table.php
//
// Menambahkan kolom bidang_id ke tabel users, supaya setiap bidang bisa
// punya SATU akun staff utama yang benar-benar terhubung lewat relasi
// database (dikelola langsung dari menu "Kelola Bidang"), bukan lagi
// murni lewat App\Models\User::BIDANG_ROLE_MAP yang hardcoded.
//
// Akun jabatan struktural lain (Kepala Dinas, Sekretaris, Kepala Bidang X,
// Kepala Sub Bagian Y) TIDAK ikut dimigrasikan di sini dan tetap memakai
// BIDANG_ROLE_MAP seperti sebelumnya — di luar cakupan perubahan ini.

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('bidang_id')
                ->nullable()
                ->unique()
                ->after('role')
                ->constrained('bidang')
                ->nullOnDelete();
        });

        // Migrasi otomatis: hubungkan akun staff yang role-nya PERSIS SAMA
        // dengan nama sebuah bidang (pola akun staff utama yang sudah ada
        // sekarang, misal role "Perencanaan dan Keuangan") ke bidang
        // terkait. Diambil satu per bidang saja untuk menjaga aturan
        // "1 bidang maksimal 1 akun staff utama" (kolom bidang_id unique).
        $bidangList = DB::table('bidang')->get(['id', 'nama']);

        foreach ($bidangList as $bidang) {
            $userId = DB::table('users')
                ->where('role', $bidang->nama)
                ->whereNull('bidang_id')
                ->orderBy('id')
                ->value('id');

            if ($userId !== null) {
                DB::table('users')->where('id', $userId)->update(['bidang_id' => $bidang->id]);
            }
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('bidang_id');
        });
    }
};
