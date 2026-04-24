// lib/providers/kegiatan_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/kegiatan_model.dart';
import '../providers/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoadState { idle, loading, loaded, error }

class KegiatanProvider extends ChangeNotifier {
  LoadState _loadState = LoadState.idle;
  List<KegiatanModel> _allKegiatan = [];
  KegiatanModel? _selected;
  String _searchQuery = '';
  String? _selectedBidang;
  DashboardSummary? _summary;
  bool _isSubmitting = false;
  String? _submitMessage;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────

  LoadState get loadState => _loadState;
  bool get isLoading => _loadState == LoadState.loading;
  bool get isLoaded => _loadState == LoadState.loaded;
  KegiatanModel? get selected => _selected;
  DashboardSummary? get summary => _summary;
  bool get isSubmitting => _isSubmitting;
  String? get submitMessage => _submitMessage;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedBidang => _selectedBidang;

  List<String> get allBidang {
    final set = <String>{};
    for (final k in _allKegiatan) set.add(k.bidang);
    return set.toList()..sort();
  }

  List<KegiatanModel> get filteredKegiatan {
    var list = List<KegiatanModel>.from(_allKegiatan);
    if (_selectedBidang != null) {
      list = list.where((k) => k.bidang == _selectedBidang).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((k) =>
        k.nama.toLowerCase().contains(q) ||
        k.bidang.toLowerCase().contains(q) ||
        k.program.toLowerCase().contains(q) ||
        k.kegiatan.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  // ── Load Dashboard ────────────────────────────────────────────────────────

  Future<void> loadDashboard() async {
  _loadState = LoadState.loading;
  _errorMessage = null;
  notifyListeners();

  try {
    final res = await DioProvider().getDashboardSummary();
    print('=== loadDashboard res: $res'); // ← lihat ini

    if (res != null && res.isNotEmpty) {
      _summary = DashboardSummary.fromJson(res);
      _loadState = LoadState.loaded;
    }
  } catch (e, st) {
    print('❌ Error: $e\n$st');
    _loadState = LoadState.error;
  }

  notifyListeners();
}
  // ── Load Kegiatan ─────────────────────────────────────────────────────────

  Future<void> loadKegiatan() async {
    _loadState = LoadState.loading;
    notifyListeners();
    await _fetchKegiatan();
  }

  Future<void> _fetchKegiatan() async {
    try {
      final data = await DioProvider().getKegiatan();
      print('Fetched kegiatan data: $data');

      if (data != null) {
        // ✅ Wrap map() dalam try tersendiri agar error parsing terlihat jelas
        try {
          _allKegiatan = data
              .map((e) => KegiatanModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loadState = LoadState.loaded;
          _errorMessage = null;
          _summary ??= DashboardSummary.fromList(_allKegiatan);
        } catch (parseError, stackTrace) {
          // ✅ Print detail error parsing agar mudah di-debug
          print('❌ Error parsing kegiatan: $parseError');
          print('Stack: $stackTrace');
          _loadState = LoadState.error;
          _errorMessage = 'Gagal memproses data: $parseError';
        }
      } else {
        _loadState = LoadState.error;
        _errorMessage = 'Gagal memuat data kegiatan';
      }
    } catch (e, stackTrace) {
      print('❌ Error fetch kegiatan: $e');
      print('Stack: $stackTrace');
      _loadState = LoadState.error;
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    print('Kegiatan list count: ${_allKegiatan.length}');
    notifyListeners();
  }

  Future<void> loadKegiatanDetail(int id) async {
    try {
      final data = await DioProvider().getKegiatanDetail(id);
      if (data != null) {
        _selected = KegiatanModel.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error load detail: $e');
    }
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void selectKegiatan(KegiatanModel kegiatan) {
    _selected = kegiatan;
    notifyListeners();
  }

  // ── Search & Filter ───────────────────────────────────────────────────────

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setBidangFilter(String? bidang) {
    _selectedBidang = bidang;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedBidang = null;
    notifyListeners();
  }

  // ── Submit Realisasi ──────────────────────────────────────────────────────

  Future<bool> submitRealisasi({
    required int kegiatanId,
    required String bulan,
    required double realisasiFisik,
    required double realisasiAnggaran,
    String? catatan,
    String? namaFile,
    String? filePath,
  }) async {
    _isSubmitting = true;
    _submitMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Cari index bulan dari nama bulan
      const bulanList = [
        'Januari','Februari','Maret','April','Mei','Juni',
        'Juli','Agustus','September','Oktober','November','Desember'
      ];
      final bulanIndex = bulanList.indexOf(bulan) + 1;

      final response = await Dio().post(
        'http://10.0.2.2:8000/api/realisasi',
        data: {
          'kegiatan_id':        kegiatanId,
          'bulan':              bulanIndex,
          'realisasi_fisik':    realisasiFisik,
          'realisasi_anggaran': realisasiAnggaran,
          if (catatan != null) 'keterangan': catatan,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _submitMessage = 'Realisasi bulan $bulan berhasil disimpan.';
        _isSubmitting = false;
        notifyListeners();

        // Refresh data kegiatan
        await _fetchKegiatan();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Gagal menyimpan realisasi';
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  void clearSubmitMessage() {
    _submitMessage = null;
    notifyListeners();
  }
}