// lib/providers/undangan_provider.dart

import 'package:flutter/material.dart';
import '../models/undangan_model.dart';
import 'dio_provider.dart';

class UndanganProvider extends ChangeNotifier {
  List<UndanganModel> _undanganList = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isUpdating = false;
  StatusUndangan? _filterStatus;
  String? _lastMessage;
  String? _errorMessage;

  // Pagination state
  int _currentPage = 0;
  int _lastPage = 1;
  static const int _perPage = 20;

  // ─── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isUpdating => _isUpdating;
  bool get hasMore => _currentPage < _lastPage;
  StatusUndangan? get filterStatus => _filterStatus;
  String? get lastMessage => _lastMessage;
  String? get errorMessage => _errorMessage;

  int get pendingCount =>
      _undanganList.where((u) => u.status == StatusUndangan.pending).length;

  // Filter dilakukan client-side dari data yang sudah di-load
  List<UndanganModel> get filteredUndangan {
    if (_filterStatus == null) return _undanganList;
    return _undanganList.where((u) => u.status == _filterStatus).toList();
  }

  List<UndanganModel> get allUndangan => _undanganList;

  // ─── Load (halaman pertama) ───────────────────────────────────────────────

  Future<void> loadUndangan() async {
    if (_isLoading) return;

    _isLoading = true;
    _currentPage = 0;
    _lastPage = 1;
    _errorMessage = null;
    notifyListeners();

    await _fetchPage(page: 1, reset: true);

    _isLoading = false;
    notifyListeners();
  }

  // ─── Load More (infinite scroll) ─────────────────────────────────────────

  Future<void> loadMoreUndangan() async {
    if (_isLoadingMore || _isLoading || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    await _fetchPage(page: _currentPage + 1, reset: false);

    _isLoadingMore = false;
    notifyListeners();
  }

  // ─── Internal fetch ───────────────────────────────────────────────────────

  Future<void> _fetchPage({required int page, required bool reset}) async {
    try {
      final result = await DioProvider().getUndangan(
        page: page,
        perPage: _perPage,
      );

      if (result != null) {
        final items = result['items'] as List<UndanganModel>;
        final currentPage = result['current_page'] as int;
        final lastPage = result['last_page'] as int;

        if (reset) {
          _undanganList = items;
        } else {
          final existingIds = _undanganList.map((u) => u.id).toSet();
          _undanganList.addAll(items.where((u) => !existingIds.contains(u.id)));
        }

        _currentPage = currentPage;
        _lastPage = lastPage;
        _errorMessage = null;
      } else {
        _errorMessage = 'Gagal memuat data undangan';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }
  }

  // ─── Filter (client-side, tidak re-fetch) ────────────────────────────────

  void setFilter(StatusUndangan? status) {
    _filterStatus = status;
    notifyListeners();
  }

  // ─── Konfirmasi Hadir ─────────────────────────────────────────────────────

  Future<bool> konfirmasiHadir({
    required int id,
    String? delegasi,
    List<int>? buktiBytes,
    String? buktiFileName,
  }) async {
    _isUpdating = true;
    _lastMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await DioProvider().postKehadiran(
        id: id,
        delegasi: delegasi,
        buktiBytes: buktiBytes,
        buktiFileName: buktiFileName,
      );

      if (result != null && result['success'] == true) {
        // Update lokal optimis
        final idx = _undanganList.indexWhere((u) => u.id == id);
        if (idx != -1) {
          final dataJson = result['data'] as Map<String, dynamic>?;
          if (dataJson != null) {
            _undanganList[idx] = UndanganModel.fromJson(dataJson);
          } else {
            _undanganList[idx] = _undanganList[idx].copyWith(
              status: StatusUndangan.hadir,
              delegasi: delegasi,
            );
          }
        }
        _lastMessage = result['message'] as String? ?? 'Kehadiran berhasil dikonfirmasi.';
        _isUpdating = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Gagal mengonfirmasi kehadiran.';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isUpdating = false;
    notifyListeners();
    return false;
  }

  // ─── Tidak Hadir ─────────────────────────────────────────────────────────

  Future<bool> tandaiTidakHadir({required int id}) async {
    _isUpdating = true;
    _lastMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await DioProvider().postTidakHadir(id: id);

      if (result != null && result['success'] == true) {
        final idx = _undanganList.indexWhere((u) => u.id == id);
        if (idx != -1) {
          _undanganList[idx] = _undanganList[idx].copyWith(
            status: StatusUndangan.tidakHadir,
          );
        }
        _lastMessage = result['message'] as String? ?? 'Undangan ditandai tidak hadir.';
        _isUpdating = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Gagal memperbarui status.';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isUpdating = false;
    notifyListeners();
    return false;
  }

  void clearMessage() {
    _lastMessage = null;
    _errorMessage = null;
    notifyListeners();
  }
}