// lib/providers/admin_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/dio_provider.dart';
import '../models/kegiatan_model.dart';

class AdminProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Kegiatan list for admin
  List<KegiatanModel> _kegiatanList = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  // Undangan list for admin
  List<Map<String, dynamic>> _undanganList = [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<KegiatanModel> get kegiatanList => _kegiatanList;
  List<Map<String, dynamic>> get undanganList => _undanganList;
  int get total => _total;
  bool get hasMore => _currentPage < _lastPage;

  // ── Kegiatan CRUD ─────────────────────────────────────────────────────────

  Future<void> loadKegiatan({int page = 1, bool reset = true}) async {
    if (reset) {
      _isLoading = true;
      _kegiatanList = [];
      _currentPage = 1;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get(
        '${DioProvider.baseApiUrl}/kegiatan',
        queryParameters: {'page': page, 'per_page': 20},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        final body = response.data['data'];
        final list = (body['data'] as List<dynamic>? ?? [])
            .map((e) => KegiatanModel.fromJson(e as Map<String, dynamic>))
            .toList();

        if (reset) {
          _kegiatanList = list;
        } else {
          final ids = _kegiatanList.map((k) => k.id).toSet();
          _kegiatanList.addAll(list.where((k) => !ids.contains(k.id)));
        }

        _currentPage = body['current_page'] ?? page;
        _lastPage = body['last_page'] ?? 1;
        _total = body['total'] ?? _kegiatanList.length;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data kegiatan';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreKegiatan() async {
    if (_isLoading || !hasMore) return;
    await loadKegiatan(page: _currentPage + 1, reset: false);
  }

  Future<bool> tambahKegiatan(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().post(
        '${DioProvider.baseApiUrl}/kegiatan',
        data: data,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 201) {
        _successMessage = 'Kegiatan berhasil ditambahkan.';
        await loadKegiatan();
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

  Future<bool> editKegiatan(int id, Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().put(
        '${DioProvider.baseApiUrl}/kegiatan/$id',
        data: data,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        _successMessage = 'Kegiatan berhasil diperbarui.';
        await loadKegiatan();
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

  Future<bool> hapusKegiatan(int id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().delete(
        '${DioProvider.baseApiUrl}/kegiatan/$id',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        _kegiatanList.removeWhere((k) => k.id == id);
        _total = (_total - 1).clamp(0, _total);
        _successMessage = 'Kegiatan berhasil dihapus.';
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

  // ── Undangan CRUD ─────────────────────────────────────────────────────────

  Future<void> loadUndangan() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get(
        '${DioProvider.baseApiUrl}/undangan',
        queryParameters: {'per_page': 50},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        final body = response.data['data'];
        _undanganList = List<Map<String, dynamic>>.from(
          (body['data'] as List<dynamic>? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat undangan';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> tambahUndangan(Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().post(
        '${DioProvider.baseApiUrl}/undangan',
        data: data,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 201) {
        _successMessage = 'Undangan berhasil ditambahkan.';
        await loadUndangan();
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

  Future<bool> editUndangan(int id, Map<String, dynamic> data) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().put(
        '${DioProvider.baseApiUrl}/undangan/$id',
        data: data,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        _successMessage = 'Undangan berhasil diperbarui.';
        await loadUndangan();
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

  Future<bool> hapusUndangan(int id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().delete(
        '${DioProvider.baseApiUrl}/undangan/$id',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        _undanganList.removeWhere((u) => u['id'] == id);
        _successMessage = 'Undangan berhasil dihapus.';
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
    if (data is Map && data['message'] != null) return data['message'];
    if (data is Map && data['errors'] != null) {
      final errors = data['errors'] as Map;
      return errors.values.first is List
          ? (errors.values.first as List).first.toString()
          : errors.values.first.toString();
    }
    return 'Server error: ${e.response?.statusCode}';
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}