// lib/providers/realisasi_provider.dart

import 'package:flutter/material.dart';
import '../models/realisasi_model.dart';
import 'dio_provider.dart';

enum RealisasiLoadState { idle, loading, loaded, error }

enum RealisasiSubmitState { idle, submitting, success, error }

class RealisasiProvider extends ChangeNotifier {
  // ── Data per kegiatan ─────────────────────────────────────────────────────
  RealisasiKegiatan? _realisasiKegiatan;
  RealisasiLoadState _loadState = RealisasiLoadState.idle;
  RealisasiSubmitState _submitState = RealisasiSubmitState.idle;

  // ── Bulan yang sedang dipilih ─────────────────────────────────────────────
  int? _selectedBulanIndex; // 1-12
  RealisasiBulanDetail? _selectedBulanData;

  String? _errorMessage;
  String? _successMessage;

  // ── Getters ───────────────────────────────────────────────────────────────
  RealisasiKegiatan? get realisasiKegiatan => _realisasiKegiatan;
  RealisasiLoadState get loadState => _loadState;
  RealisasiSubmitState get submitState => _submitState;
  int? get selectedBulan => _selectedBulanIndex;
  RealisasiBulanDetail? get selectedBulanData => _selectedBulanData;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get isLoading => _loadState == RealisasiLoadState.loading;
  bool get isSubmitting => _submitState == RealisasiSubmitState.submitting;
  bool get hasData => _realisasiKegiatan != null;

  // =========================================================================
  // LOAD DATA REALISASI PER KEGIATAN
  // =========================================================================

  Future<void> loadRealisasi(int kegiatanId) async {
    _loadState = RealisasiLoadState.loading;
    _realisasiKegiatan = null;
    _selectedBulanIndex = null;
    _selectedBulanData = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await DioProvider().getRealisasiDetail(kegiatanId);
      if (data != null) {
        _realisasiKegiatan = RealisasiKegiatan.fromJson(data);
        _loadState = RealisasiLoadState.loaded;
        print(
          '✓ Realisasi loaded: ${_realisasiKegiatan?.perBulan.length} bulan',
        );
      } else {
        _loadState = RealisasiLoadState.error;
        _errorMessage = 'Gagal memuat data realisasi';
      }
    } catch (e, st) {
      print('❌ loadRealisasi error: $e\n$st');
      _loadState = RealisasiLoadState.error;
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    notifyListeners();
  }

  // =========================================================================
  // PILIH BULAN → AUTO-FILL FORM
  // =========================================================================

  void selectBulan(int bulanIndex, {bool clearMessages = true}) {
    _selectedBulanIndex = bulanIndex;
    _selectedBulanData = _realisasiKegiatan?.getBulan(bulanIndex);
    _submitState = RealisasiSubmitState.idle;
    if (clearMessages) {
      _errorMessage = null;
      _successMessage = null;
    }
    notifyListeners();
  }

  void clearBulan() {
    _selectedBulanIndex = null;
    _selectedBulanData = null;
    notifyListeners();
  }

  // =========================================================================
  // SUBMIT REALISASI
  // =========================================================================

  Future<bool> submitRealisasi({
    required int kegiatanId,
    required int bulan,
    required double realisasiFisik,
    required double realisasiAnggaran,
    String? keterangan,
  }) async {
    _submitState = RealisasiSubmitState.submitting;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final ok = await DioProvider().postRealisasi(
        kegiatanId: kegiatanId,
        bulan: bulan,
        realisasiFisik: realisasiFisik,
        realisasiAnggaran: realisasiAnggaran,
        keterangan: keterangan,
      );

      if (ok) {
        await loadRealisasi(kegiatanId);
        selectBulan(bulan, clearMessages: false);

        _submitState = RealisasiSubmitState.success;
        _successMessage =
            'Realisasi bulan ${_namaBulan(bulan)} berhasil disimpan.';
        notifyListeners();
        return true;
      } else {
        _submitState = RealisasiSubmitState.error;
        _errorMessage = 'Server menolak data. Periksa input.';
        notifyListeners();
        return false;
      }
    } catch (e, st) {
      print('❌ submitRealisasi error: $e\n$st');
      _submitState = RealisasiSubmitState.error;
      _errorMessage = 'Gagal menyimpan: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadBukti({
    required int kegiatanId,
    required int bulan,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    _submitState = RealisasiSubmitState.submitting;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await DioProvider().uploadBukti(
        kegiatanId: kegiatanId,
        bulan: bulan,
        fileName: fileName,
        fileBytes: fileBytes,
      );

      if (result != null && result['success'] == true) {
        await loadRealisasi(kegiatanId);
        selectBulan(bulan, clearMessages: false);

        _submitState = RealisasiSubmitState.success;
        _successMessage =
            result['message'] as String? ?? 'Bukti berhasil diunggah.';
        notifyListeners();
        return true;
      }

      _submitState = RealisasiSubmitState.error;
      _errorMessage = 'Gagal mengunggah bukti. Periksa format dan ukuran file.';
      notifyListeners();
      return false;
    } catch (e, st) {
      print('uploadBukti error: $e\n$st');
      _submitState = RealisasiSubmitState.error;
      _errorMessage = 'Gagal mengunggah bukti: $e';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void reset() {
    _realisasiKegiatan = null;
    _loadState = RealisasiLoadState.idle;
    _submitState = RealisasiSubmitState.idle;
    _selectedBulanIndex = null;
    _selectedBulanData = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  String _namaBulan(int b) {
    const list = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return (b >= 1 && b <= 12) ? list[b] : '-';
  }
}
