// lib/models/bidang_model.dart

import 'package:equatable/equatable.dart';

class BidangModel extends Equatable {
  final int id;
  final String nama;
  final String? keterangan;
  final int? userId;
  final String? username;

  const BidangModel({
    required this.id,
    required this.nama,
    this.keterangan,
    this.userId,
    this.username,
  });

  /// Apakah bidang ini sudah punya akun staff utama.
  bool get hasAccount => username != null && username!.isNotEmpty;

  factory BidangModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    int? userId;
    String? username;

    if (userJson is Map) {
      final userMap = Map<String, dynamic>.from(userJson);
      userId = userMap['id'] is int
          ? userMap['id'] as int
          : int.tryParse('${userMap['id']}');
      username = userMap['username']?.toString();
    }

    return BidangModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      nama: json['nama']?.toString() ?? '',
      keterangan: json['keterangan'] as String?,
      userId: userId,
      username: username,
    );
  }

  @override
  List<Object?> get props => [id, nama, keterangan, userId, username];
}
