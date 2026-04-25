// lib/models/realisasi_model.dart

/// Data realisasi satu bulan dari endpoint GET /api/kegiatan/{id}/realisasi
class RealisasiBulanDetail {
  final int bulan;
  final String namaBulan;
  final double? fisik;
  final double? anggaran;
  final String? keterangan;
  final BuktiDetail? bukti;

  const RealisasiBulanDetail({
    required this.bulan,
    required this.namaBulan,
    this.fisik,
    this.anggaran,
    this.keterangan,
    this.bukti,
  });

  bool get hasData => fisik != null || anggaran != null;

  static double? _toDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory RealisasiBulanDetail.fromJson(Map<String, dynamic> json) {
    return RealisasiBulanDetail(
      bulan:      json['bulan'] as int,
      namaBulan:  json['nama_bulan'] ?? '',
      fisik:      _toDoubleNullable(json['fisik']),
      anggaran:   _toDoubleNullable(json['anggaran']),
      keterangan: json['keterangan'] as String?,
      bukti:      json['bukti'] != null && (json['bukti'] as Map).isNotEmpty
                    ? BuktiDetail.fromJson(json['bukti'] as Map<String, dynamic>)
                    : null,
    );
  }
}

class BuktiDetail {
  final int id;
  final int bulan;
  final String filePath;
  final String? fileUrl;

  const BuktiDetail({
    required this.id,
    required this.bulan,
    required this.filePath,
    this.fileUrl,
  });

  String get fileName => filePath.split('/').last;

  bool get isPdf => filePath.toLowerCase().endsWith('.pdf');
  bool get isImage =>
      filePath.toLowerCase().endsWith('.jpg') ||
      filePath.toLowerCase().endsWith('.jpeg') ||
      filePath.toLowerCase().endsWith('.png');

  factory BuktiDetail.fromJson(Map<String, dynamic> json) {
    return BuktiDetail(
      id:       json['id'] as int,
      bulan:    json['bulan'] as int,
      filePath: json['file_path'] ?? '',
      fileUrl:  json['file_url'] as String?,
    );
  }
}

/// Wrapper untuk semua data realisasi satu kegiatan
class RealisasiKegiatan {
  final int kegiatanId;
  final String kegiatanNama;
  final double paguAnggaran;
  final List<RealisasiBulanDetail> perBulan;
  final double totalFisik;
  final double totalAnggaran;
  final double persenAnggaran;

  const RealisasiKegiatan({
    required this.kegiatanId,
    required this.kegiatanNama,
    required this.paguAnggaran,
    required this.perBulan,
    required this.totalFisik,
    required this.totalAnggaran,
    required this.persenAnggaran,
  });

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory RealisasiKegiatan.fromJson(Map<String, dynamic> json) {
    final perBulanRaw = json['per_bulan'] as List<dynamic>? ?? [];
    return RealisasiKegiatan(
      kegiatanId:   json['kegiatan_id'] as int,
      kegiatanNama: json['kegiatan_nama'] ?? '',
      paguAnggaran: _d(json['pagu_anggaran']),
      perBulan:     perBulanRaw
                      .map((e) => RealisasiBulanDetail.fromJson(
                            e as Map<String, dynamic>))
                      .toList(),
      totalFisik:   _d(json['total_fisik']),
      totalAnggaran: _d(json['total_anggaran']),
      persenAnggaran: _d(json['persen_anggaran']),
    );
  }

  /// Ambil data satu bulan berdasarkan nomor bulan (1-12)
  RealisasiBulanDetail? getBulan(int bulan) {
    try {
      return perBulan.firstWhere((b) => b.bulan == bulan);
    } catch (_) {
      return null;
    }
  }
}