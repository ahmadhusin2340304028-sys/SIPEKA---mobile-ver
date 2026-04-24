<?php
// database/seeders/DatabaseSeeder.php

namespace Database\Seeders;

use App\Models\Kegiatan;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        DB::table('realisasi_fisik')->truncate();
        DB::table('realisasi_anggaran')->truncate();
        DB::table('keterangan_kegiatan')->truncate();
        DB::table('bukti_kegiatan')->truncate();
        DB::table('undangan')->truncate();
        DB::table('kegiatan')->truncate();
        DB::table('users')->truncate();
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        // ── Users (sesuai screenshot) ─────────────────────────────────────────
        $users = [
            ['username' => 'admin',                 'password' => 'dinsos123', 'role' => 'Admin'],
            ['username' => 'kadis',                 'password' => 'dinsos123', 'role' => 'Kepala Dinas'],
            ['username' => 'staff perencanaan',     'password' => 'dinsos123', 'role' => 'Perencanaan dan Keuangan'],
            ['username' => 'staff umum',            'password' => 'dinsos123', 'role' => 'Umum dan Kepegawaian'],
            ['username' => 'staff resos',           'password' => 'dinsos123', 'role' => 'Rehabilitasi Sosial'],
            ['username' => 'staff linjamsos',       'password' => 'dinsos123', 'role' => 'Perlindungan dan Jaminan Sosial'],
            ['username' => 'staff dayasos',         'password' => 'dinsos123', 'role' => 'Pemberdayaan Sosial'],
            ['username' => 'staff PM',              'password' => 'dinsos123', 'role' => 'Pemberdayaan Masyarakat'],
            ['username' => 'kabid sosial',          'password' => 'dinsos123', 'role' => 'Kepala Bidang Sosial'],
            ['username' => 'kasubbag perencanaan',  'password' => 'dinsos123', 'role' => 'Kepala Sub Bagian Perencanaan'],
            ['username' => 'kabid pm',              'password' => 'dinsos123', 'role' => 'Kepala Bidang Pemberdayaan Masyarakat'],
            ['username' => 'kasubbag kepegawaian',  'password' => 'dinsos123', 'role' => 'Kepala Sub Bagian Kepegawaian'],
            ['username' => 'Sekretaris',            'password' => 'dinsos123', 'role' => 'Sekretaris'],
        ];

        foreach ($users as $u) {
            User::create($u);
        }

        // ── Kegiatan (sesuai screenshot data) ────────────────────────────────
        $kegiatan = [
            [
                'sasaran_strategis' => 'Peningkatan Kinerja Perencanaan',
                'indikator_kinerja' => 'Persentase dokumen perencanaan tepat waktu',
                'satuan'            => '%',
                'target'            => 100.00,
                'tahun'             => 2025,
                'bidang'            => 'Perencanaan dan Keuangan',
                'program'           => 'Program Perencanaan',
                'kegiatan'          => 'Penyusunan RKPD',
                'sub_kegiatan'      => 'Koordinasi penyusunan RKPD',
                'pagu_anggaran'     => 50000000.00,
            ],
            [
                'sasaran_strategis' => 'Peningkatan Layanan Administrasi',
                'indikator_kinerja' => 'Jumlah layanan administrasi terpenuhi',
                'satuan'            => 'dokumen',
                'target'            => 200.00,
                'tahun'             => 2025,
                'bidang'            => 'Umum dan Kepegawaian',
                'program'           => 'Program Administrasi',
                'kegiatan'          => 'Pengelolaan Surat',
                'sub_kegiatan'      => 'Distribusi surat masuk dan keluar',
                'pagu_anggaran'     => 30000000.00,
            ],
            [
                'sasaran_strategis' => 'Pemulihan Sosial Masyarakat',
                'indikator_kinerja' => 'Jumlah penerima manfaat rehabilitasi',
                'satuan'            => 'orang',
                'target'            => 150.00,
                'tahun'             => 2025,
                'bidang'            => 'Rehabilitasi Sosial',
                'program'           => 'Program Rehabilitasi',
                'kegiatan'          => 'Pelayanan Rehabilitasi',
                'sub_kegiatan'      => 'Pendampingan sosial',
                'pagu_anggaran'     => 75000000.00,
            ],
            [
                'sasaran_strategis' => 'Perlindungan Sosial',
                'indikator_kinerja' => 'Jumlah bantuan tersalurkan',
                'satuan'            => 'KK',
                'target'            => 500.00,
                'tahun'             => 2025,
                'bidang'            => 'Perlindungan dan Jaminan Sosial',
                'program'           => 'Program Perlindungan',
                'kegiatan'          => 'Penyaluran Bantuan',
                'sub_kegiatan'      => 'Distribusi bantuan sosial',
                'pagu_anggaran'     => 100000000.00,
            ],
            [
                'sasaran_strategis' => 'Pemberdayaan Sosial',
                'indikator_kinerja' => 'Jumlah kelompok sosial aktif',
                'satuan'            => 'kelompok',
                'target'            => 80.00,
                'tahun'             => 2025,
                'bidang'            => 'Pemberdayaan Sosial',
                'program'           => 'Program Pemberdayaan',
                'kegiatan'          => 'Pembinaan Kelompok',
                'sub_kegiatan'      => 'Pelatihan kelompok sosial',
                'pagu_anggaran'     => 60000000.00,
            ],
            [
                'sasaran_strategis' => 'Pemberdayaan Masyarakat',
                'indikator_kinerja' => 'Jumlah masyarakat terlatih',
                'satuan'            => 'orang',
                'target'            => 300.00,
                'tahun'             => 2025,
                'bidang'            => 'Pemberdayaan Masyarakat',
                'program'           => 'Program Pelatihan',
                'kegiatan'          => 'Pelatihan Keterampilan',
                'sub_kegiatan'      => 'Pelatihan UMKM',
                'pagu_anggaran'     => 85000000.00,
            ],
        ];

        foreach ($kegiatan as $k) {
            Kegiatan::create($k);
        }

        $this->command->info('✓ Seeder selesai: ' . count($users) . ' users, ' . count($kegiatan) . ' kegiatan.');
    }
}
