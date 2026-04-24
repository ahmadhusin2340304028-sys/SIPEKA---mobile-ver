// lib/screens/kegiatan/input_realisasi_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/kegiatan_provider.dart';

class InputRealisasiScreen extends StatefulWidget {
  const InputRealisasiScreen({super.key});

  @override
  State<InputRealisasiScreen> createState() => _InputRealisasiScreenState();
}

class _InputRealisasiScreenState extends State<InputRealisasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fisikCtrl = TextEditingController();
  final _anggaranCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  String? _selectedBulan;
  String? _selectedFile; // UI only - simulates file selection
  bool _hasFile = false;

  @override
  void dispose() {
    _fisikCtrl.dispose();
    _anggaranCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  void _simulateFilePick() {
    setState(() {
      _hasFile = true;
      _selectedFile =
          'bukti_realisasi_${_selectedBulan ?? 'juni'}_2025.pdf';
    });
  }

  void _removeFile() {
    setState(() {
      _hasFile = false;
      _selectedFile = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBulan == null) {
      AppUtils.showError(context, 'Pilih bulan terlebih dahulu.');
      return;
    }
    FocusScope.of(context).unfocus();

    final kp = context.read<KegiatanProvider>();
    final kegiatan = kp.selected;
    if (kegiatan == null) return;

    final fisikVal =
        double.tryParse(_fisikCtrl.text.replaceAll(',', '.')) ?? 0;
    final anggaranVal =
        double.tryParse(_anggaranCtrl.text.replaceAll('.', '')) ?? 0;

    final ok = await kp.submitRealisasi(
      kegiatanId: kegiatan.id,
      bulan: _selectedBulan!,
      realisasiFisik: fisikVal,
      realisasiAnggaran: anggaranVal,
      catatan: _catatanCtrl.text.trim().isEmpty
          ? null
          : _catatanCtrl.text.trim(),
      namaFile: _selectedFile,
    );

    if (!mounted) return;
    if (ok) {
      AppUtils.showSuccess(
          context, kp.submitMessage ?? 'Realisasi berhasil disimpan.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kp = context.watch<KegiatanProvider>();
    final kegiatan = kp.selected;
    final isSubmitting = kp.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.inputRealisasi)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Kegiatan Banner ─────────────────────────────────────────────
            if (kegiatan != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(11),
                  border: const Border(
                    left: BorderSide(
                        color: AppColors.primary, width: 3.5),
                    top: BorderSide(
                        color: Color(0xFFBFDBFE), width: 0.5),
                    right: BorderSide(
                        color: Color(0xFFBFDBFE), width: 0.5),
                    bottom: BorderSide(
                        color: Color(0xFFBFDBFE), width: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kegiatan.nama,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${kegiatan.bidang} · ${kegiatan.tahun} · ${AppUtils.formatCurrencyCompact(kegiatan.anggaran)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.primaryMid),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),

            // ── Pilih Bulan ──────────────────────────────────────────────────
            _FormField(
              label: 'Periode Bulan *',
              child: DropdownButtonFormField<String>(
                value: _selectedBulan,
                hint: const Text('Pilih bulan realisasi'),
                decoration: const InputDecoration(),
                items: AppMonths.list
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBulan = v),
                validator: (v) => v == null ? 'Pilih bulan' : null,
              ),
            ),
            const SizedBox(height: 14),

            // ── Realisasi Fisik ──────────────────────────────────────────────
            _FormField(
              label: 'Realisasi Fisik (%) *',
              hint: 'Masukkan persentase fisik yang sudah tercapai',
              child: TextFormField(
                controller: _fisikCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[\d,.]')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Contoh: 85',
                  suffixText: '%',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Realisasi fisik wajib diisi';
                  }
                  final val =
                      double.tryParse(v.replaceAll(',', '.'));
                  if (val == null) return 'Angka tidak valid';
                  if (val < 0 || val > 100) {
                    return 'Nilai harus antara 0 dan 100';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Realisasi Anggaran ───────────────────────────────────────────
            _FormField(
              label: 'Realisasi Anggaran (Rp) *',
              hint: 'Nominal anggaran yang sudah terealisasi bulan ini',
              child: TextFormField(
                controller: _anggaranCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  hintText: 'Contoh: 350000000',
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Realisasi anggaran wajib diisi';
                  }
                  final val = double.tryParse(v);
                  if (val == null || val < 0) {
                    return 'Nominal tidak valid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Catatan ──────────────────────────────────────────────────────
            _FormField(
              label: 'Catatan / Keterangan',
              hint: 'Opsional — tambahkan informasi pendukung',
              child: TextFormField(
                controller: _catatanCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  hintText: 'Masukkan catatan jika diperlukan...',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Upload Bukti ─────────────────────────────────────────────────
            _FormField(
              label: 'Bukti Pendukung',
              hint: 'PDF, JPG, PNG — maks 5 MB',
              child: _hasFile
                  ? _SelectedFileCard(
                      name: _selectedFile!,
                      onRemove: _removeFile,
                    )
                  : _UploadBox(onTap: _simulateFilePick),
            ),
            const SizedBox(height: 28),

            // ── Submit ───────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Realisasi',
                        style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Form Field Wrapper ───────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const _FormField({
    required this.label,
    required this.child,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
        ],
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─── Upload Box ───────────────────────────────────────────────────────────────

class _UploadBox extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF93C5FD), width: 1.5,
              style: BorderStyle.solid),
        ),
        child: const Column(
          children: [
            Icon(Icons.upload_file_rounded,
                size: 32, color: AppColors.primaryMid),
            SizedBox(height: 8),
            Text(
              'Tap untuk pilih file',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryMid,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'PDF, JPG, PNG — maksimal 5 MB',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Selected File Card ───────────────────────────────────────────────────────

class _SelectedFileCard extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _SelectedFileCard({required this.name, required this.onRemove});

  IconData get _icon => name.endsWith('.pdf')
      ? Icons.picture_as_pdf_rounded
      : Icons.image_rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF86EFAC), width: 0.75),
      ),
      child: Row(
        children: [
          Icon(_icon, size: 30, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Siap diunggah',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textMuted),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
