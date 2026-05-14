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

  // ✅ Server-side search query
  String _searchQuery = '';

  // Undangan list for admin
  List<Map<String, dynamic>> _undanganList = [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<KegiatanModel> get kegiatanList => _kegiatanList;
  List<Map<String, dynamic>> get undanganList => _undanganList;
  String get searchQuery => _searchQuery;
  int get total => _total;
  bool get hasMore => _currentPage < _lastPage;

  // ── Kegiatan CRUD ─────────────────────────────────────────────────────────

  Future<void> loadKegiatan({int page = 1, bool reset = true}) async {
    if (reset) {
      _isLoading = true;
      _kegiatanList = [];
      _currentPage = 1;
      _lastPage = 1;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get(
        '${DioProvider.baseApiUrl}/kegiatan',
        queryParameters: {
          'page': page,
          'per_page': 20,
          // ✅ Kirim search ke server jika ada
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        },
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

        _currentPage = _asInt(body['current_page'], page);
        _lastPage    = _asInt(body['last_page'], 1);
        _total       = _asInt(body['total'], _kegiatanList.length);
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

  /// ✅ Set search → reload dari halaman 1 (server-side)
  Future<void> setSearch(String query) async {
    if (_searchQuery == query.trim()) return;
    _searchQuery = query.trim();
    await loadKegiatan();
  }

  /// ✅ Hapus search → reload semua data
  Future<void> clearSearch() async {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    await loadKegiatan();
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

      final payload = _normalizeUndanganPayload(data);

      final response = await Dio().post(
        '${DioProvider.baseApiUrl}/undangan',
        data: payload,
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

      _errorMessage = _parseResponseError(response.data);
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

      final payload = _normalizeUndanganPayload(data);

      final response = await Dio().put(
        '${DioProvider.baseApiUrl}/undangan/$id',
        data: payload,
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

      _errorMessage = _parseResponseError(response.data);
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

  Map<String, dynamic> _normalizeUndanganPayload(Map<String, dynamic> data) {
    const adminFields = {
      'judul_kegiatan',
      'tanggal',
      'waktu',
      'tempat',
      'pihak_mengundang',
      'bidang_terkait',
    };

    final payload = Map<String, dynamic>.fromEntries(
      data.entries.where((e) => adminFields.contains(e.key)),
    );

    if (payload.containsKey('bidang_terkait')) {
      final raw = payload['bidang_terkait'];
      if (raw is List) {
        payload['bidang_terkait'] = raw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (raw is String) {
        payload['bidang_terkait'] = raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return payload;
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    return _parseResponseError(data) ??
        'Server error: ${e.response?.statusCode}';
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