// lib/models/undangan_model.dart

import 'package:equatable/equatable.dart';

enum StatusUndangan { hadir, tidakHadir, pending }

class UndanganModel extends Equatable {
  final int id;
  final String judul;
  final String penyelenggara;
  final DateTime tanggal;
  final String jam;
  final String lokasi;
  final StatusUndangan status;
  final String? kegiatanTerkait;
  final String? catatan;

  const UndanganModel({
    required this.id,
    required this.judul,
    required this.penyelenggara,
    required this.tanggal,
    required this.jam,
    required this.lokasi,
    required this.status,
    this.kegiatanTerkait,
    this.catatan,
  });

  UndanganModel copyWith({StatusUndangan? status, String? catatan}) {
    return UndanganModel(
      id: id,
      judul: judul,
      penyelenggara: penyelenggara,
      tanggal: tanggal,
      jam: jam,
      lokasi: lokasi,
      status: status ?? this.status,
      kegiatanTerkait: kegiatanTerkait,
      catatan: catatan ?? this.catatan,
    );
  }

  String get statusLabel {
    switch (status) {
      case StatusUndangan.hadir:
        return 'Hadir';
      case StatusUndangan.tidakHadir:
        return 'Tidak Hadir';
      case StatusUndangan.pending:
        return 'Pending';
    }
  }

  @override
  List<Object?> get props => [id];
}

// ─── Mock Data ────────────────────────────────────────────────────────────────

final List<UndanganModel> kMockUndangan = [
  UndanganModel(
    id: 1,
    judul: 'Rapat Koordinasi Anggaran Triwulan III',
    penyelenggara: 'Bappeda',
    tanggal: DateTime(2025, 7, 17),
    jam: '09:00',
    lokasi: 'Aula Dinas PU Lantai 2',
    status: StatusUndangan.pending,
    kegiatanTerkait: 'Penyusunan RPJMD 2025–2030',
  ),
  UndanganModel(
    id: 2,
    judul: 'Peninjauan Lapangan Jalan Lingkar Barat',
    penyelenggara: 'Dinas PU',
    tanggal: DateTime(2025, 6, 12),
    jam: '08:00',
    lokasi: 'Lokasi Proyek Km 14, Balikpapan Barat',
    status: StatusUndangan.hadir,
    kegiatanTerkait: 'Pembangunan Jalan Lingkar Barat',
    catatan: 'Progres sesuai jadwal, dilanjutkan bulan berikutnya.',
  ),
  UndanganModel(
    id: 3,
    judul: 'Workshop Evaluasi Kinerja SKPD Semester I',
    penyelenggara: 'Inspektorat Daerah',
    tanggal: DateTime(2025, 7, 20),
    jam: '13:00',
    lokasi: 'Hotel Bumi Asih, Ruang Bougenville',
    status: StatusUndangan.pending,
  ),
  UndanganModel(
    id: 4,
    judul: 'Sosialisasi Regulasi Keuangan Daerah 2025',
    penyelenggara: 'BPKD',
    tanggal: DateTime(2025, 6, 25),
    jam: '10:00',
    lokasi: 'Aula Bappeda Lt. 3',
    status: StatusUndangan.hadir,
    catatan: 'Paparan regulasi baru tentang pelaporan keuangan daerah.',
  ),
  UndanganModel(
    id: 5,
    judul: 'Rapat Teknis Pengadaan Puskesmas',
    penyelenggara: 'Dinas Kesehatan',
    tanggal: DateTime(2025, 6, 5),
    jam: '14:00',
    lokasi: 'Kantor Dinas Kesehatan',
    status: StatusUndangan.tidakHadir,
    kegiatanTerkait: 'Pengadaan Sarana Puskesmas',
    catatan: 'Berhalangan hadir karena tugas dinas luar.',
  ),
  UndanganModel(
    id: 6,
    judul: 'Monitoring dan Evaluasi Digitalisasi Arsip',
    penyelenggara: 'Diskominfo',
    tanggal: DateTime(2025, 7, 28),
    jam: '09:30',
    lokasi: 'Ruang Rapat Diskominfo',
    status: StatusUndangan.pending,
    kegiatanTerkait: 'Digitalisasi Arsip Daerah',
  ),
];
