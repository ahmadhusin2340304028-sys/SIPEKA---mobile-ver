// lib/providers/undangan_provider.dart

import 'package:flutter/material.dart';
import '../models/undangan_model.dart';

class UndanganProvider extends ChangeNotifier {
  List<UndanganModel> _undanganList = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  StatusUndangan? _filterStatus;
  String? _lastMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  StatusUndangan? get filterStatus => _filterStatus;
  String? get lastMessage => _lastMessage;

  int get pendingCount =>
      _undanganList.where((u) => u.status == StatusUndangan.pending).length;

  List<UndanganModel> get filteredUndangan {
    if (_filterStatus == null) return _undanganList;
    return _undanganList.where((u) => u.status == _filterStatus).toList();
  }

  List<UndanganModel> get allUndangan => _undanganList;

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadUndangan() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    _undanganList = List<UndanganModel>.from(kMockUndangan);
    _isLoading = false;
    notifyListeners();
  }

  // ─── Filter ───────────────────────────────────────────────────────────────

  void setFilter(StatusUndangan? status) {
    _filterStatus = status;
    notifyListeners();
  }

  // ─── Status Update ────────────────────────────────────────────────────────

  Future<bool> updateStatus({
    required int id,
    required StatusUndangan newStatus,
    String? catatan,
  }) async {
    _isUpdating = true;
    _lastMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final idx = _undanganList.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _undanganList[idx] = _undanganList[idx].copyWith(
        status: newStatus,
        catatan: catatan,
      );

      final statusLabel = _undanganList[idx].statusLabel;
      _lastMessage = 'Status berhasil diperbarui menjadi "$statusLabel".';
    }

    _isUpdating = false;
    notifyListeners();
    return true;
  }

  void clearMessage() {
    _lastMessage = null;
    notifyListeners();
  }
}
