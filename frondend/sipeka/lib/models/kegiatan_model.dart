// lib/models/kegiatan_model.dart

import 'package:equatable/equatable.dart';

// lib/models/kegiatan_model.dart

class KegiatanModel extends Equatable {
  final int id;
  final String sasaranStrategis;
  final String indikatorKinerja;
  final String satuan;
  final double target;
  final int tahun;
  final String bidang;
  final String program;
  final String kegiatan;
  final String subKegiatan;
  final double paguAnggaran;
  final double totalRealisasiFisik;
  final double totalRealisasiAnggaran;
  final double persenFisik; // ✅ field proper, bukan getter null
  final double persenAnggaran;
  final double sisaTarget; // ✅ field proper, bukan getter null
  final double sisaAnggaran;
  final List<RealisasiBulan>
  realisasiBulanan; // ✅ field proper, bukan getter null
  final bool canManage;

  const KegiatanModel({
    required this.id,
    required this.sasaranStrategis,
    required this.indikatorKinerja,
    required this.satuan,
    required this.target,
    required this.tahun,
    required this.bidang,
    required this.program,
    required this.kegiatan,
    required this.subKegiatan,
    required this.paguAnggaran,
    this.totalRealisasiFisik = 0,
    this.totalRealisasiAnggaran = 0,
    this.persenFisik = 0,
    this.persenAnggaran = 0,
    this.sisaTarget = 0,
    this.sisaAnggaran = 0,
    this.realisasiBulanan = const [], // ✅ default list kosong
    this.canManage = false,
  });

  String get nama => subKegiatan;
  double get progressFisik => persenFisik;
  double get progressAnggaran => persenAnggaran;
  num get anggaran => paguAnggaran;

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static bool _toBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is int) return val == 1;
    if (val is String) {
      final normalized = val.toLowerCase().trim();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  factory KegiatanModel.fromJson(Map<String, dynamic> json) {
    List<RealisasiBulan> bulanan = [];
    if (json['realisasi_fisik'] != null) {
      final rawFisik = json['realisasi_fisik'] as List<dynamic>;
      final rawAnggaran = json['realisasi_anggaran'] as List<dynamic>? ?? [];

      bulanan = rawFisik.map((e) {
        final map = e as Map<String, dynamic>;
        final bulan = map['bulan'] as int;
        final anggaranEntry = rawAnggaran.firstWhere(
          (a) => (a as Map<String, dynamic>)['bulan'] == bulan,
          orElse: () => {'bulan': bulan, 'nilai': 0},
        );
        return RealisasiBulan(
          bulan: bulan,
          fisik: _toDouble(map['nilai']),
          anggaran: _toDouble((anggaranEntry as Map<String, dynamic>)['nilai']),
        );
      }).toList()..sort((a, b) => a.bulan.compareTo(b.bulan));
    }

    return KegiatanModel(
      id: json['id'] as int,
      sasaranStrategis: json['sasaran_strategis'] ?? '',
      indikatorKinerja: json['indikator_kinerja'] ?? '',
      satuan: json['satuan'] ?? '',
      target: _toDouble(json['target']),
      tahun: json['tahun'] as int,
      bidang: json['bidang'] ?? '',
      program: json['program'] ?? '',
      kegiatan: json['kegiatan'] ?? '',
      subKegiatan: json['sub_kegiatan'] ?? '',
      paguAnggaran: _toDouble(json['pagu_anggaran']),
      totalRealisasiFisik: _toDouble(json['total_realisasi_fisik']),
      totalRealisasiAnggaran: _toDouble(json['total_realisasi_anggaran']),
      persenFisik: _toDouble(
        json['persen_target'],
      ), // ✅ ganti dari 'persen_fisik'
      persenAnggaran: _toDouble(json['persen_anggaran']),
      sisaTarget: _toDouble(json['sisa_target']),
      sisaAnggaran: _toDouble(json['sisa_anggaran']),
      realisasiBulanan: bulanan,
      canManage: _toBool(json['can_manage']),
    );
  }

  @override
  List<Object?> get props => [id];
}

// ✅ Class RealisasiBulan yang sebenarnya
class RealisasiBulan {
  final int bulan;
  final double fisik;
  final double anggaran;

  const RealisasiBulan({
    required this.bulan,
    required this.fisik,
    required this.anggaran,
  });

  factory RealisasiBulan.fromJson(Map<String, dynamic> json) {
    return RealisasiBulan(
      bulan: json['bulan'] as int,
      fisik: (json['nilai'] ?? 0)
          .toDouble(), // kolom 'nilai' di tabel realisasi_fisik
      anggaran: 0, // akan diisi dari join jika perlu
    );
  }
}

class DashboardSummary {
  final int totalKegiatan;
  final double rataRataFisik;
  final double rataRataAnggaran;
  final double totalTarget;
  final double totalAnggaran;
  final double totalRealisasi;
  final List<BidangProgress> bidangProgress;
  final double totalRealisasiFisik;

  DashboardSummary({
    required this.totalKegiatan,
    required this.rataRataFisik,
    required this.rataRataAnggaran,
    required this.totalTarget,
    required this.totalAnggaran,
    required this.totalRealisasi,
    required this.bidangProgress,
    required this.totalRealisasiFisik,
  });

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalKegiatan: json['total_kegiatan'] is int
          ? json['total_kegiatan'] as int
          : int.tryParse(json['total_kegiatan'].toString()) ?? 0,
      rataRataFisik: _d(json['rata_realisasi_fisik']),
      rataRataAnggaran: _d(json['persen_anggaran']),
      totalTarget: _d(json['total_target']),
      totalAnggaran: _d(json['total_pagu_anggaran']),
      totalRealisasi: _d(json['total_realisasi_anggaran']),
      totalRealisasiFisik: _d(json['total_realisasi_fisik']),
      bidangProgress: (json['bidang_progress'] as List<dynamic>? ?? [])
          .map((e) => BidangProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ← fallback dari list lokal
  factory DashboardSummary.fromList(List<KegiatanModel> list) {
    if (list.isEmpty) {
      return DashboardSummary(
        totalKegiatan: 0,
        rataRataFisik: 0,
        rataRataAnggaran: 0,
        totalTarget: 0,
        totalAnggaran: 0,
        totalRealisasi: 0,
        bidangProgress: [],
        totalRealisasiFisik: 0,
      );
    }
    return DashboardSummary(
      totalKegiatan: list.length,
      rataRataFisik:
          list.map((k) => k.progressFisik).reduce((a, b) => a + b) /
          list.length,
      rataRataAnggaran:
          list.map((k) => k.persenAnggaran).reduce((a, b) => a + b) /
          list.length,
      totalTarget: list.map((k) => k.target).reduce((a, b) => a + b),
      totalAnggaran: list.map((k) => k.paguAnggaran).reduce((a, b) => a + b),
      totalRealisasi: list
          .map((k) => k.totalRealisasiAnggaran)
          .reduce((a, b) => a + b),
      totalRealisasiFisik: list
          .map((k) => k.totalRealisasiFisik)
          .reduce((a, b) => a + b),
      bidangProgress: list
          .fold<Map<String, List<KegiatanModel>>>({}, (map, k) {
            map.putIfAbsent(k.bidang, () => []).add(k);
            return map;
          })
          .entries
          .map((e) {
            final totalTarget = e.value
                .map((k) => k.target)
                .reduce((a, b) => a + b);

            final totalRealisasiFisik = e.value
                .map((k) => k.totalRealisasiFisik)
                .reduce((a, b) => a + b);

            final progress = totalTarget > 0
                ? (totalRealisasiFisik / totalTarget) * 100
                : 0.0;

            return BidangProgress(
              nama: e.key,
              progress: progress,

              // kalau kamu sudah tambah field ini di model
              totalTarget: totalTarget,
              totalRealisasiFisik: totalRealisasiFisik,
            );
          })
          .toList(),
    );
  }
}

class BidangProgress {
  final String nama;
  final double progress;
  final double totalTarget;
  final double totalRealisasiFisik;

  BidangProgress({
    required this.nama,
    required this.progress,
    required this.totalTarget,
    required this.totalRealisasiFisik,
  });

  factory BidangProgress.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return double.tryParse(v.toString()) ?? 0;
    }

    return BidangProgress(
      nama: json['nama'] ?? '',
      progress: toDouble(json['progress']),
      totalTarget: toDouble(json['total_target']),
      totalRealisasiFisik: toDouble(json['total_realisasi_fisik']),
    );
  }
}
