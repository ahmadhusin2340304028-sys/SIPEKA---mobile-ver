// lib/providers/bidang_provider.dart
//
// Menyimpan daftar "bidang" (master data yang dikelola Admin lewat menu
// Kelola Bidang). Provider ini dipakai sebagai SATU-SATUNYA sumber data
// bidang di seluruh aplikasi Flutter — dropdown input Kegiatan, filter
// Kegiatan, checklist pihak diundang Undangan, filter Export, dst — supaya
// semuanya konsisten mengikuti apa yang sudah diatur admin.
//
// Setiap bidang bisa punya SATU akun staff utama (username & password)
// yang dikelola langsung lewat form Tambah/Edit Bidang.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bidang_model.dart';
import 'dio_provider.dart';

class BidangProvider extends ChangeNotifier {
  List<BidangModel> _bidangList = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<BidangModel> get bidangList => _bidangList;

  /// Daftar nama bidang saja — siap pakai untuk dropdown/filter.
  List<String> get namaList => _bidangList.map((b) => b.nama).toList();

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // ── Load ──────────────────────────────────────────────────────────────────

  /// GET /api/bidang — bisa dipanggil oleh role apa pun yang sudah login.
  Future<void> loadBidang() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get(
        '${DioProvider.baseApiUrl}/bidang',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = (response.data['data'] as List<dynamic>? ?? [])
            .map((e) => BidangModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _bidangList = list;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data bidang';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── CRUD (Admin) ─────────────────────────────────────────────────────────

  /// [username]/[password] opsional — isi untuk langsung membuat akun
  /// staff utama bidang ini. [password] wajib diisi kalau [username] diisi.
  Future<bool> tambahBidang({
    required String nama,
    String? keterangan,
    String? username,
    String? password,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().post(
        '${DioProvider.baseApiUrl}/bidang',
        data: {
          'nama': nama,
          if (keterangan != null && keterangan.isNotEmpty) 'keterangan': keterangan,
          if (username != null && username.isNotEmpty) 'username': username,
          if (password != null && password.isNotEmpty) 'password': password,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 201) {
        _successMessage =
            response.data['message'] as String? ?? 'Bidang berhasil ditambahkan.';
        await loadBidang();
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  /// [username]/[password] opsional. Kalau bidang sudah punya akun,
  /// [password] boleh dikosongkan (artinya kata sandi tidak diubah).
  Future<bool> editBidang(
    int id, {
    required String nama,
    String? keterangan,
    String? username,
    String? password,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().put(
        '${DioProvider.baseApiUrl}/bidang/$id',
        data: {
          'nama': nama,
          'keterangan': keterangan ?? '',
          if (username != null && username.isNotEmpty) 'username': username,
          if (password != null && password.isNotEmpty) 'password': password,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        _successMessage =
            response.data['message'] as String? ?? 'Bidang berhasil diperbarui.';
        await loadBidang();
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  /// Menghapus bidang SEKALIGUS seluruh kegiatan, undangan terkait, dan
  /// akun staff bidangnya (cascade dilakukan di backend). Flutter yang
  /// memanggil ini bertanggung jawab memastikan admin sudah dikonfirmasi
  /// 2 kali sebelumnya (lihat admin_bidang_screen.dart).
  Future<bool> hapusBidang(int id) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().delete(
        '${DioProvider.baseApiUrl}/bidang/$id',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        _bidangList.removeWhere((b) => b.id == id);
        _successMessage =
            response.data['message'] as String? ?? 'Bidang berhasil dihapus.';
        _isSaving = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isSaving = false;
    notifyListeners();
    return false;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _parseError(DioException e) {
    final data = e.response?.data;
    return _parseResponseError(data) ?? 'Server error: ${e.response?.statusCode}';
  }

  String? _parseResponseError(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      if (data['message'] != null) return data['message'].toString();
      if (data['errors'] != null) {
        final errors = data['errors'] as Map;
        final first = errors.values.first;
        return first is List ? first.first.toString() : first.toString();
      }
    }
    return null;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
