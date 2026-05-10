// lib/models/undangan_model.dart

import 'package:equatable/equatable.dart';

enum StatusUndangan { hadir, tidakHadir, pending }

class UndanganModel extends Equatable {
  final int id;
  final String judul;           // judul_kegiatan
  final DateTime tanggal;
  final String waktu;           // jam HH:mm
  final String tempat;
  final String pihakMengundang; // pihak_mengundang
  final String bidangTerkait;   // comma-separated string (raw dari DB)
  final List<String> pihakTerkait; // parsed list dari bidang_terkait
  final StatusUndangan status;  // dari menghadiri
  final String? menghadiri;     // siapa yang hadir (username/bidang user yg login)
  final String? bukti;          // path file bukti
  final String? buktiUrl;       // URL full untuk akses file
  final String? delegasi;       // keterangan delegasi
  final String statusKegiatan;  // Belum Dilaksanakan / Sudah Dilaksanakan
  final bool canRespond;        // boleh konfirmasi hadir/tidak hadir

  const UndanganModel({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.waktu,
    required this.tempat,
    required this.pihakMengundang,
    required this.bidangTerkait,
    required this.pihakTerkait,
    required this.status,
    this.menghadiri,
    this.bukti,
    this.buktiUrl,
    this.delegasi,
    required this.statusKegiatan,
    this.canRespond = true,
  });

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

  static StatusUndangan _parseStatus(String? menghadiri) {
    final value = menghadiri?.trim().toLowerCase() ?? '';
    if (value.isEmpty || value == 'pending') return StatusUndangan.pending;
    if (value == 'tidak hadir') return StatusUndangan.tidakHadir;
    return StatusUndangan.hadir;
  }

  /// Parse bidang_terkait — comma-separated string
  /// Input: "Kepala Dinas, Perencanaan dan Keuangan, Umum dan Kepegawaian"
  /// Output: ["Kepala Dinas", "Perencanaan dan Keuangan", "Umum dan Kepegawaian"]
  static List<String> _parsePihakTerkait(dynamic raw) {
    if (raw == null) return [];
    
    final str = raw.toString().trim();
    if (str.isEmpty) return [];
    
    // Split by comma dan trim setiap item
    return str
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  factory UndanganModel.fromJson(Map<String, dynamic> json) {
    final menghadiri = json['menghadiri'] as String?;
    final bidangTerkaitRaw = json['bidang_terkait'] ?? '';
    
    return UndanganModel(
      id: json['id'] as int,
      judul: json['judul_kegiatan'] ?? '',
      tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
      waktu: (json['waktu'] ?? '').toString().substring(0, 5), // HH:mm
      tempat: json['tempat'] ?? '',
      pihakMengundang: json['pihak_mengundang'] ?? '',
      bidangTerkait: bidangTerkaitRaw,
      pihakTerkait: _parsePihakTerkait(bidangTerkaitRaw),
      status: _parseStatus(menghadiri),
      menghadiri: menghadiri,
      bukti: json['bukti'] as String?,
      buktiUrl: json['bukti_url'] as String?,
      delegasi: json['delegasi'] as String?,
      statusKegiatan: json['status_kegiatan'] ?? 'Belum Dilaksanakan',
      canRespond: json['can_respond'] is bool
          ? json['can_respond'] as bool
          : true,
    );
  }

  UndanganModel copyWith({
    StatusUndangan? status,
    String? menghadiri,
    String? buktiUrl,
    String? delegasi,
    String? statusKegiatan,
    bool? canRespond,
  }) {
    return UndanganModel(
      id: id,
      judul: judul,
      tanggal: tanggal,
      waktu: waktu,
      tempat: tempat,
      pihakMengundang: pihakMengundang,
      bidangTerkait: bidangTerkait,
      pihakTerkait: pihakTerkait,
      status: status ?? this.status,
      menghadiri: menghadiri ?? this.menghadiri,
      bukti: bukti,
      buktiUrl: buktiUrl ?? this.buktiUrl,
      delegasi: delegasi ?? this.delegasi,
      statusKegiatan: statusKegiatan ?? this.statusKegiatan,
      canRespond: canRespond ?? this.canRespond,
    );
  }

  @override
  List<Object?> get props => [id];
}
