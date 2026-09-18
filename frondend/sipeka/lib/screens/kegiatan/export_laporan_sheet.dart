// lib/screens/kegiatan/export_laporan_sheet.dart
//
// Bottom sheet dengan filter laporan + tombol Export Excel & PDF.
// Dipanggil dari KegiatanScreen via floating action button.

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/dio_provider.dart';
import '../../providers/bidang_provider.dart';

// ─── Konstanta ────────────────────────────────────────────────────────────────

const List<_MinFisikOption> _kMinFisikOptions = [
  _MinFisikOption(label: 'Semua', value: null),
  _MinFisikOption(label: '≥ 30%', value: 30),
  _MinFisikOption(label: '≥ 50%', value: 50),
  _MinFisikOption(label: '≥ 90%', value: 90),
  _MinFisikOption(label: '100%', value: 100),
];

class _MinFisikOption {
  final String label;
  final int? value;
  const _MinFisikOption({required this.label, required this.value});
}

// ─── Entry point ─────────────────────────────────────────────────────────────

/// Tampilkan bottom sheet export laporan.
void showExportLaporanSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ExportLaporanSheet(),
  );
}

// ─── Bottom Sheet Widget ──────────────────────────────────────────────────────

class _ExportLaporanSheet extends StatefulWidget {
  const _ExportLaporanSheet();

  @override
  State<_ExportLaporanSheet> createState() => _ExportLaporanSheetState();
}

class _ExportLaporanSheetState extends State<_ExportLaporanSheet> {
  String _selectedBidang = 'Semua';
  int _selectedTahun = DateTime.now().year;
  _MinFisikOption _selectedMinFisik = _kMinFisikOptions.first;

  bool _isExportingExcel = false;
  bool _isExportingPdf = false;

  @override
  void initState() {
    super.initState();
    // ✅ Muat daftar bidang (master data) untuk dropdown filter di bawah.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BidangProvider>().loadBidang();
    });
  }

  List<int> get _tahunOptions {
    final now = DateTime.now().year;
    return List.generate(5, (i) => now - i);
  }

  // ── Export Excel ────────────────────────────────────────────────────────

  Future<void> _exportExcel() async {
    setState(() => _isExportingExcel = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final params = <String, dynamic>{'tahun': _selectedTahun};
      if (_selectedBidang != 'Semua') params['bidang'] = _selectedBidang;
      if (_selectedMinFisik.value != null)
        params['min_fisik'] = _selectedMinFisik.value;

      final response = await Dio().get(
        '${DioProvider.baseApiUrl}/export/excel',
        queryParameters: params,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept':
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final bytes = Uint8List.fromList(response.data as List<int>);
        await _saveAndOpen(bytes, 'laporan_kegiatan_$_selectedTahun.xlsx');
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) AppUtils.showError(context, 'Gagal export Excel: $e');
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  // ── Export PDF ──────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final params = <String, dynamic>{'tahun': _selectedTahun};
      if (_selectedBidang != 'Semua') params['bidang'] = _selectedBidang;
      if (_selectedMinFisik.value != null)
        params['min_fisik'] = _selectedMinFisik.value;

      // Backend mengembalikan HTML → kita simpan sebagai .html
      // dan buka di browser (bisa di-print ke PDF dari browser)
      final response = await Dio().get(
        '${DioProvider.baseApiUrl}/export/pdf',
        queryParameters: params,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'text/html',
          },
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final bytes = Uint8List.fromList(response.data as List<int>);
        await _saveAndOpen(bytes, 'laporan_kegiatan_$_selectedTahun.html');
      } else {
        throw Exception('Server error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) AppUtils.showError(context, 'Gagal export PDF: $e');
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  // ── Simpan file & buka ──────────────────────────────────────────────────

  Future<void> _saveAndOpen(Uint8List bytes, String filename) async {
    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) dir = await getTemporaryDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final path = '${dir.path}/$filename';
    final file = File(path);
    await file.writeAsBytes(bytes);

    if (mounted) {
      Navigator.pop(context);
      AppUtils.showSuccess(context, 'File disimpan: $path');
      await Future.delayed(const Duration(milliseconds: 600));
      await OpenFilex.open(path);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    // ✅ Daftar bidang untuk filter sekarang dinamis, mengikuti data yang
    // diatur admin lewat menu "Kelola Bidang" — bukan lagi list hardcoded.
    final bidangList = ['Semua', ...context.watch<BidangProvider>().namaList];

    return Container(
      height: screenH * 0.80,
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Seksi/Bidang ──────────────────────────────────────
                  _sectionLabel('Seksi / Urusan'),
                  const SizedBox(height: 8),
                  _buildDropdown<String>(
                    value: bidangList.contains(_selectedBidang)
                        ? _selectedBidang
                        : 'Semua',
                    items: bidangList,
                    labelBuilder: (v) => v,
                    onChanged: (v) =>
                        setState(() => _selectedBidang = v ?? 'Semua'),
                  ),
                  const SizedBox(height: 18),

                  // ── Tahun ─────────────────────────────────────────────
                  _sectionLabel('Tahun'),
                  const SizedBox(height: 8),
                  _buildDropdown<int>(
                    value: _selectedTahun,
                    items: _tahunOptions,
                    labelBuilder: (v) => v.toString(),
                    onChanged: (v) =>
                        setState(() => _selectedTahun = v ?? _selectedTahun),
                  ),
                  const SizedBox(height: 18),

                  // ── Realisasi Kinerja Minimal ─────────────────────────
                  _sectionLabel('Realisasi Kinerja Minimal'),
                  const SizedBox(height: 8),
                  _buildDropdown<_MinFisikOption>(
                    value: _selectedMinFisik,
                    items: _kMinFisikOptions,
                    labelBuilder: (v) => v.label,
                    onChanged: (v) => setState(
                        () => _selectedMinFisik = v ?? _kMinFisikOptions.first),
                  ),
                  const SizedBox(height: 28),

                  // ── Preview kriteria ──────────────────────────────────
                  _buildCriteriaPreview(),
                  const SizedBox(height: 28),

                  // ── Tombol Export ─────────────────────────────────────
                  _buildExportButton(
                    label: 'Export Excel',
                    icon: Icons.table_chart_rounded,
                    color: const Color(0xFF16A34A),
                    isLoading: _isExportingExcel,
                    onTap: (_isExportingPdf || _isExportingExcel)
                        ? null
                        : _exportExcel,
                  ),
                  const SizedBox(height: 12),
                  _buildExportButton(
                    label: 'Export PDF (HTML)',
                    icon: Icons.picture_as_pdf_rounded,
                    color: AppColors.danger,
                    isLoading: _isExportingPdf,
                    onTap: (_isExportingPdf || _isExportingExcel)
                        ? null
                        : _exportPdf,
                    outlined: true,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'File akan tersimpan di folder Download',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMutedOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderOf(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.filter_alt_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filter Laporan Kegiatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: AppTheme.textMutedOf(context)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 0, color: AppTheme.borderOf(context)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.textSecondaryOf(context),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrayOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderOf(context), width: 0.75),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMutedOf(context)),
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimaryOf(context),
          ),
          dropdownColor: AppTheme.surfaceOf(context),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelBuilder(item)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCriteriaPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Kriteria Laporan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _criteriaRow('Bidang', _selectedBidang),
          _criteriaRow('Tahun', _selectedTahun.toString()),
          _criteriaRow('Min. Kinerja', _selectedMinFisik.label),
        ],
      ),
    );
  }

  Widget _criteriaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.primaryMid)),
          ),
          const Text(': ',
              style: TextStyle(fontSize: 12, color: AppColors.primaryMid)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback? onTap,
    bool outlined = false,
  }) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              : Icon(icon, size: 18, color: color),
          label: Text(
            isLoading ? 'Mengekspor...' : label,
            style: TextStyle(fontSize: 15, color: color),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 18),
        label: Text(
          isLoading ? 'Mengekspor...' : label,
          style: const TextStyle(fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
