-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 30, 2026 at 08:23 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sipeka`
--

-- --------------------------------------------------------

--
-- Table structure for table `bukti_kegiatan`
--

CREATE TABLE `bukti_kegiatan` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `kegiatan_id` bigint(20) UNSIGNED NOT NULL,
  `bulan` tinyint(3) UNSIGNED NOT NULL,
  `file_path` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `kegiatan`
--

CREATE TABLE `kegiatan` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `sasaran_strategis` varchar(255) NOT NULL,
  `indikator_kinerja` varchar(255) NOT NULL,
  `satuan` varchar(50) NOT NULL,
  `target` decimal(10,2) NOT NULL,
  `tahun` year(4) NOT NULL,
  `bidang` varchar(100) NOT NULL,
  `program` varchar(255) NOT NULL,
  `kegiatan` varchar(255) NOT NULL,
  `sub_kegiatan` varchar(255) NOT NULL,
  `pagu_anggaran` decimal(15,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `kegiatan`
--

INSERT INTO `kegiatan` (`id`, `sasaran_strategis`, `indikator_kinerja`, `satuan`, `target`, `tahun`, `bidang`, `program`, `kegiatan`, `sub_kegiatan`, `pagu_anggaran`, `created_at`, `updated_at`) VALUES
(1, 'Peningkatan Kinerja Perencanaan', 'Persentase dokumen perencanaan tepat waktu', '%', 100.00, '2026', 'Perencanaan dan Keuangan', 'Program Perencanaan', 'Penyusunan RKPD', 'Koordinasi penyusunan RKPD', 50000000.00, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(2, 'Peningkatan Layanan Administrasi', 'Jumlah layanan administrasi terpenuhi', 'dokumen', 200.00, '2026', 'Umum dan Kepegawaian', 'Program Administrasi', 'Pengelolaan Surat', 'Distribusi surat masuk dan keluar', 30000000.00, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(3, 'Pemulihan Sosial Masyarakat', 'Jumlah penerima manfaat rehabilitasi', 'orang', 150.00, '2026', 'Rehabilitasi Sosial', 'Program Rehabilitasi', 'Pelayanan Rehabilitasi', 'Pendampingan sosial', 75000000.00, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(4, 'Perlindungan Sosial', 'Jumlah bantuan tersalurkan', 'KK', 500.00, '2026', 'Perlindungan dan Jaminan Sosial', 'Program Perlindungan', 'Penyaluran Bantuan', 'Distribusi bantuan sosial', 100000000.00, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(5, 'Pemberdayaan Sosial', 'Jumlah kelompok sosial aktif', 'kelompok', 80.00, '2026', 'Pemberdayaan Sosial', 'Program Pemberdayaan', 'Pembinaan Kelompok', 'Pelatihan kelompok sosial', 60000000.00, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(6, 'Pemberdayaan Masyarakat', 'Jumlah masyarakat terlatih', 'orang', 300.00, '2026', 'Pemberdayaan Masyarakat', 'Program Pelatihan', 'Pelatihan Keterampilan', 'Pelatihan UMKM', 85000000.00, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(7, 'tes', 'tes', 'orang', 200.00, '2026', 'Perencanaan dan Keuangan', 'tes', 'tes', 'tes', 200000000.00, '2026-04-24 06:52:13', '2026-04-24 06:52:13'),
(8, 'Karyawan korban PHK', 'Jumlah Karyawan', 'orang', 300.00, '2026', 'Pemberdayaan Sosial', 'Pemberian Masukan Harian', 'Distribusi Makanan', 'Distribusi Mie Soto Ayam', 200000000.00, '2026-04-24 12:09:21', '2026-04-24 12:09:21');

-- --------------------------------------------------------

--
-- Table structure for table `keterangan_kegiatan`
--

CREATE TABLE `keterangan_kegiatan` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `kegiatan_id` bigint(20) UNSIGNED NOT NULL,
  `bulan` tinyint(3) UNSIGNED NOT NULL,
  `keterangan` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `keterangan_kegiatan`
--

INSERT INTO `keterangan_kegiatan` (`id`, `kegiatan_id`, `bulan`, `keterangan`) VALUES
(1, 1, 2, 'niceeeeee'),
(2, 7, 1, 'amaannn'),
(3, 7, 2, 'terealisasi daerah prikanan');

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2025_01_01_000001_create_sipeka_tables', 1);

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `realisasi_anggaran`
--

CREATE TABLE `realisasi_anggaran` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `kegiatan_id` bigint(20) UNSIGNED NOT NULL,
  `bulan` tinyint(3) UNSIGNED NOT NULL,
  `nilai` decimal(15,2) NOT NULL COMMENT 'Nominal rupiah'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `realisasi_anggaran`
--

INSERT INTO `realisasi_anggaran` (`id`, `kegiatan_id`, `bulan`, `nilai`) VALUES
(1, 1, 1, 12000000.00),
(2, 6, 1, 20000000.00),
(3, 6, 2, 12000000.00),
(4, 8, 1, 20000000.00),
(5, 1, 2, 12000000.00),
(6, 7, 1, 25000000.00),
(7, 7, 2, 10000000.00);

-- --------------------------------------------------------

--
-- Table structure for table `realisasi_fisik`
--

CREATE TABLE `realisasi_fisik` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `kegiatan_id` bigint(20) UNSIGNED NOT NULL,
  `bulan` tinyint(3) UNSIGNED NOT NULL,
  `nilai` decimal(15,2) NOT NULL COMMENT 'Persentase 0-100'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `realisasi_fisik`
--

INSERT INTO `realisasi_fisik` (`id`, `kegiatan_id`, `bulan`, `nilai`) VALUES
(1, 1, 1, 12.00),
(2, 6, 1, 50.00),
(3, 6, 6, 50.00),
(4, 7, 1, 10.00),
(5, 7, 2, 20.00),
(6, 3, 1, 20.00),
(7, 2, 1, 40.00),
(8, 4, 1, 50.00),
(9, 5, 1, 20.00),
(10, 8, 1, 20.00),
(11, 1, 2, 10.00);

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('PImauaglHyUYVT55Gk4RqEqIyeOkRbQKI1iPWW9c', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiUUs4cnRicjlkT0RCZWFsU0VUYjlxRVJIc2tzT0hVR2MzWGFUVElOSSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMCI7czo1OiJyb3V0ZSI7Tjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1776612015),
('PNiKCjpoe9mk5xeZRx4iLKLx1B5Pp12Loedjrx2F', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiUmMwUDVydFFOOUprd2JlT1VlTmNCQkh0UTdrVzBEZmJYTXR6M3VyUiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMCI7czo1OiJyb3V0ZSI7Tjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1776656344),
('WX8jH5Jr2oAsPbr6K28x1XbxrxhjWD8rK7opdgiU', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiWE1waHE0czNnMlRwZW1QRzEwSHBoQ3NFVW83eTRFdlNnYlFubTByMyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6MjE6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMCI7czo1OiJyb3V0ZSI7Tjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319fQ==', 1776699446);

-- --------------------------------------------------------

--
-- Table structure for table `undangan`
--

CREATE TABLE `undangan` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `judul_kegiatan` varchar(255) NOT NULL,
  `tanggal` date NOT NULL,
  `waktu` time NOT NULL,
  `tempat` varchar(255) NOT NULL,
  `pihak_mengundang` varchar(255) NOT NULL,
  `bidang_terkait` varchar(150) NOT NULL,
  `status_kegiatan` varchar(50) NOT NULL DEFAULT 'Belum Dilaksanakan',
  `menghadiri` varchar(50) NOT NULL DEFAULT 'Pending',
  `bukti` varchar(255) DEFAULT NULL,
  `delegasi` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(100) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `role`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'admin', 'dinsos123', 'Admin', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(2, 'kadis', 'dinsos123', 'Kepala Dinas', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(3, 'staff_perencanaan', 'dinsos123', 'Perencanaan dan Keuangan', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(4, 'staff_umum', 'dinsos123', 'Umum dan Kepegawaian', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(5, 'staff_resos', 'dinsos123', 'Rehabilitasi Sosial', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(6, 'staff_linjamsos', 'dinsos123', 'Perlindungan dan Jaminan Sosial', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(7, 'staff_dayasos', 'dinsos123', 'Pemberdayaan Sosial', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(8, 'staff_PM', 'dinsos123', 'Pemberdayaan Masyarakat', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(9, 'kabid_sosial', 'dinsos123', 'Kepala Bidang Sosial', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(10, 'kasubbag_perencanaan', 'dinsos123', 'Kepala Sub Bagian Perencanaan', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(11, 'kabid_pm', 'dinsos123', 'Kepala Bidang Pemberdayaan Masyarakat', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(12, 'kasubbag_kepegawaian', 'dinsos123', 'Kepala Sub Bagian Kepegawaian', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(13, 'Sekretaris', 'dinsos123', 'Sekretaris', NULL, '2026-04-19 07:16:36', '2026-04-19 07:16:36'),
(14, 'husin', '123456', 'Rehabilitasi Sosial', NULL, NULL, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bukti_kegiatan`
--
ALTER TABLE `bukti_kegiatan`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `bukti_kegiatan_kegiatan_id_bulan_unique` (`kegiatan_id`,`bulan`),
  ADD KEY `bukti_kegiatan_kegiatan_id_index` (`kegiatan_id`);

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `kegiatan`
--
ALTER TABLE `kegiatan`
  ADD PRIMARY KEY (`id`),
  ADD KEY `kegiatan_tahun_bidang_index` (`tahun`,`bidang`);

--
-- Indexes for table `keterangan_kegiatan`
--
ALTER TABLE `keterangan_kegiatan`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `keterangan_kegiatan_kegiatan_id_bulan_unique` (`kegiatan_id`,`bulan`),
  ADD KEY `keterangan_kegiatan_kegiatan_id_index` (`kegiatan_id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `realisasi_anggaran`
--
ALTER TABLE `realisasi_anggaran`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `realisasi_anggaran_kegiatan_id_bulan_unique` (`kegiatan_id`,`bulan`),
  ADD KEY `realisasi_anggaran_kegiatan_id_index` (`kegiatan_id`);

--
-- Indexes for table `realisasi_fisik`
--
ALTER TABLE `realisasi_fisik`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `realisasi_fisik_kegiatan_id_bulan_unique` (`kegiatan_id`,`bulan`),
  ADD KEY `realisasi_fisik_kegiatan_id_index` (`kegiatan_id`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `undangan`
--
ALTER TABLE `undangan`
  ADD PRIMARY KEY (`id`),
  ADD KEY `undangan_tanggal_bidang_terkait_index` (`tanggal`,`bidang_terkait`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_username_unique` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bukti_kegiatan`
--
ALTER TABLE `bukti_kegiatan`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `kegiatan`
--
ALTER TABLE `kegiatan`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `keterangan_kegiatan`
--
ALTER TABLE `keterangan_kegiatan`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=89;

--
-- AUTO_INCREMENT for table `realisasi_anggaran`
--
ALTER TABLE `realisasi_anggaran`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `realisasi_fisik`
--
ALTER TABLE `realisasi_fisik`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `undangan`
--
ALTER TABLE `undangan`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bukti_kegiatan`
--
ALTER TABLE `bukti_kegiatan`
  ADD CONSTRAINT `bukti_kegiatan_kegiatan_id_foreign` FOREIGN KEY (`kegiatan_id`) REFERENCES `kegiatan` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `keterangan_kegiatan`
--
ALTER TABLE `keterangan_kegiatan`
  ADD CONSTRAINT `keterangan_kegiatan_kegiatan_id_foreign` FOREIGN KEY (`kegiatan_id`) REFERENCES `kegiatan` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `realisasi_anggaran`
--
ALTER TABLE `realisasi_anggaran`
  ADD CONSTRAINT `realisasi_anggaran_kegiatan_id_foreign` FOREIGN KEY (`kegiatan_id`) REFERENCES `kegiatan` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `realisasi_fisik`
--
ALTER TABLE `realisasi_fisik`
  ADD CONSTRAINT `realisasi_fisik_kegiatan_id_foreign` FOREIGN KEY (`kegiatan_id`) REFERENCES `kegiatan` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
