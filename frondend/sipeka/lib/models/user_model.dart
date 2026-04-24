import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String username;
  final String role;
  final String? bidang;      // ✅ nullable — Admin tidak punya bidang
  final bool canManage;

  const UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.bidang,             // ✅ optional
    required this.canManage,
  });

  String get initials {
    final parts = username.trim().split(RegExp(r'[_\s]+'));
    if (parts.length == 1) {
      return parts[0]
          .substring(0, parts[0].length.clamp(0, 2))
          .toUpperCase();
    }
    return parts
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join()
        .toUpperCase();
  }

  // ✅ Label yang ditampilkan di drawer sebagai subtitle
  String get roleLabel {
    if (bidang != null && bidang!.isNotEmpty) {
      return bidang!;       // Staff: tampil nama bidang
    }
    return role;            // Admin/Kadis/Sekretaris: tampil role
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      bidang: json['bidang'] as String?,     // ✅ cast nullable
      canManage: json['can_manage'] as bool,
    );
  }

  @override
  List<Object?> get props => [id, username];
}