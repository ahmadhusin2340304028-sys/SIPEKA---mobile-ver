// lib/screens/admin/admin_kegiatan_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/kegiatan_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_drawer.dart';

const List<String> kBidangList = [
  'Perencanaan dan Keuangan',
  'Umum dan Kepegawaian',
  'Rehabilitasi Sosial',
  'Perlindungan dan Jaminan Sosial',
  'Pemberdayaan Sosial',
  'Pemberdayaan Masyarakat',
];

class AdminKegiatanScreen extends StatefulWidget {
  const AdminKegiatanScreen({super.key});

  @override
  State<AdminKegiatanScreen> createState() => _AdminKegiatanScreenState();
}

class _AdminKegiatanScreenState extends State<AdminKegiatanScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  // ✅ Debounce timer — tunda request sampai user berhenti mengetik
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadKegiatan();
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<AdminProvider>().loadMoreKegiatan();
    }
  }

  // ✅ Server-side search dengan debounce 400ms
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<AdminProvider>().setSearch(value);
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _debounce?.cancel();
    context.read<AdminProvider>().clearSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kegiatan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showKegiatanDialog(context),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Tambah Kegiatan',
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              // ✅ Pakai server-side search, bukan setState
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari kegiatan, bidang, program...',
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppColors.textMuted),
                suffixIcon: ap.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 18, color: AppColors.textMuted),
                        onPressed: _clearSearch,
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const Divider(height: 0),

          // ── Stats bar ─────────────────────────────────────────────────
          Container(
            color: AppColors.surfaceGray,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${ap.total} kegiatan',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                if (ap.searchQuery.isNotEmpty) ...[
                  const Text(' · ',
                      style: TextStyle(color: AppColors.textMuted)),
                  Text(
                    'hasil pencarian "${ap.searchQuery}"',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 0),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: ap.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ap.kegiatanList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ap.searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.folder_open_rounded,
                              size: 56,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ap.searchQuery.isNotEmpty
                                  ? 'Tidak ada hasil untuk "${ap.searchQuery}"'
                                  : 'Belum ada data kegiatan',
                              style: const TextStyle(
                                  color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                            if (ap.searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _clearSearch,
                                child: const Text('Hapus pencarian'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ap.loadKegiatan(),
                        child: ListView.separated(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: ap.kegiatanList.length +
                              (ap.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            if (i >= ap.kegiatanList.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            final k = ap.kegiatanList[i];
                            return _KegiatanAdminCard(
                              kegiatan: k,
                              onEdit: () =>
                                  _showKegiatanDialog(context, kegiatan: k),
                              onHapus: () =>
                                  _confirmHapusKegiatan(context, k),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showKegiatanDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showKegiatanDialog(BuildContext context, {KegiatanModel? kegiatan}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _KegiatanDialog(kegiatan: kegiatan),
    );
  }

  Future<void> _confirmHapusKegiatan(
      BuildContext context, KegiatanModel kegiatan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 22),
          SizedBox(width: 8),
          Text('Konfirmasi Hapus'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hapus kegiatan berikut?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                kegiatan.nama,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data realisasi fisik, anggaran, keterangan, dan bukti akan ikut terhapus.',
              style:
                  TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ap = context.read<AdminProvider>();
      final ok = await ap.hapusKegiatan(kegiatan.id);
      if (mounted) {
        if (ok) {
          AppUtils.showSuccess(
              context, ap.successMessage ?? 'Berhasil dihapus');
        } else {
          AppUtils.showError(
              context, ap.errorMessage ?? 'Gagal menghapus');
        }
        ap.clearMessages();
      }
    }
  }
}

// ─── Kegiatan Admin Card ──────────────────────────────────────────────────────

class _KegiatanAdminCard extends StatelessWidget {
  final KegiatanModel kegiatan;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const _KegiatanAdminCard({
    required this.kegiatan,
    required this.onEdit,
    required this.onHapus,
  });

  Color get _bidangColor {
    switch (kegiatan.bidang) {
      case 'Perencanaan dan Keuangan':
        return const Color(0xFF1A56DB);
      case 'Umum dan Kepegawaian':
        return const Color(0xFF16A34A);
      case 'Rehabilitasi Sosial':
        return const Color(0xFF7C3AED);
      case 'Perlindungan dan Jaminan Sosial':
        return const Color(0xFFD97706);
      case 'Pemberdayaan Sosial':
        return const Color(0xFF0891B2);
      case 'Pemberdayaan Masyarakat':
        return const Color(0xFF65A30D);
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: _bidangColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                  bottom: BorderSide(
                      color: _bidangColor.withOpacity(0.15), width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: _bidangColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kegiatan.bidang,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _bidangColor),
                  ),
                ),
                Text(
                  kegiatan.tahun.toString(),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kegiatan.nama,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  kegiatan.program,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      label:
                          'Target: ${kegiatan.target.toStringAsFixed(0)} ${kegiatan.satuan}',
                      icon: Icons.flag_rounded,
                    ),
                    const SizedBox(width: 6),
                    _InfoChip(
                      label: AppUtils.formatCurrencyCompact(
                          kegiatan.paguAnggaran),
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text('Edit',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onHapus,
                  icon: const Icon(Icons.delete_outline_rounded, size: 15),
                  label: const Text('Hapus',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Kegiatan Dialog ──────────────────────────────────────────────────────────

class _KegiatanDialog extends StatefulWidget {
  final KegiatanModel? kegiatan;
  const _KegiatanDialog({this.kegiatan});

  @override
  State<_KegiatanDialog> createState() => _KegiatanDialogState();
}

class _KegiatanDialogState extends State<_KegiatanDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _sasaranCtrl;
  late final TextEditingController _indikatorCtrl;
  late final TextEditingController _programCtrl;
  late final TextEditingController _kegiatanCtrl;
  late final TextEditingController _subKegiatanCtrl;
  late final TextEditingController _satuanCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _tahunCtrl;
  late final TextEditingController _paguCtrl;
  String? _selectedBidang;

  bool get _isEdit => widget.kegiatan != null;

  @override
  void initState() {
    super.initState();
    final k = widget.kegiatan;
    _sasaranCtrl =
        TextEditingController(text: k?.sasaranStrategis ?? '');
    _indikatorCtrl =
        TextEditingController(text: k?.indikatorKinerja ?? '');
    _programCtrl = TextEditingController(text: k?.program ?? '');
    _kegiatanCtrl = TextEditingController(text: k?.kegiatan ?? '');
    _subKegiatanCtrl =
        TextEditingController(text: k?.subKegiatan ?? '');
    _satuanCtrl = TextEditingController(text: k?.satuan ?? '');
    _targetCtrl = TextEditingController(
        text: k != null ? k.target.toStringAsFixed(0) : '');
    _tahunCtrl = TextEditingController(
        text: k?.tahun.toString() ?? DateTime.now().year.toString());
    _paguCtrl = TextEditingController(
        text: k != null ? k.paguAnggaran.toStringAsFixed(0) : '');
    _selectedBidang = k?.bidang;
    if (_selectedBidang != null &&
        !kBidangList.contains(_selectedBidang)) {
      _selectedBidang = null;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _sasaranCtrl,
      _indikatorCtrl,
      _programCtrl,
      _kegiatanCtrl,
      _subKegiatanCtrl,
      _satuanCtrl,
      _targetCtrl,
      _tahunCtrl,
      _paguCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBidang == null) {
      AppUtils.showError(context, 'Silakan pilih bidang/urusan.');
      return;
    }

    FocusScope.of(context).unfocus();

    final ap = context.read<AdminProvider>();
    final data = {
      'sasaran_strategis': _sasaranCtrl.text.trim(),
      'indikator_kinerja': _indikatorCtrl.text.trim(),
      'program': _programCtrl.text.trim(),
      'kegiatan': _kegiatanCtrl.text.trim(),
      'sub_kegiatan': _subKegiatanCtrl.text.trim(),
      'satuan': _satuanCtrl.text.trim(),
      'target': double.tryParse(_targetCtrl.text) ?? 0,
      'tahun': int.tryParse(_tahunCtrl.text) ?? DateTime.now().year,
      'pagu_anggaran': double.tryParse(_paguCtrl.text) ?? 0,
      'bidang': _selectedBidang,
    };

    bool ok;
    if (_isEdit) {
      ok = await ap.editKegiatan(widget.kegiatan!.id, data);
    } else {
      ok = await ap.tambahKegiatan(data);
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      AppUtils.showSuccess(
          context, ap.successMessage ?? 'Berhasil disimpan');
      ap.clearMessages();
    } else {
      AppUtils.showError(
          context, ap.errorMessage ?? 'Gagal menyimpan');
      ap.clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.task_alt_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Kegiatan' : 'Tambah Kegiatan',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField('Sasaran Strategis', _sasaranCtrl,
                        maxLines: 3),
                    _buildField('Indikator Kinerja', _indikatorCtrl,
                        maxLines: 2),
                    _buildField('Program', _programCtrl, maxLines: 2),
                    _buildField('Kegiatan', _kegiatanCtrl,
                        maxLines: 2),
                    _buildField('Sub Kegiatan', _subKegiatanCtrl,
                        maxLines: 2),

                    // Row: Satuan | Target | Tahun
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildField('Satuan', _satuanCtrl,
                              hint: '%, Orang, Lembaga'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildField('Target', _targetCtrl,
                              inputType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              formatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]'))
                              ]),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildField('Tahun', _tahunCtrl,
                              inputType: TextInputType.number,
                              formatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Wajib';
                                }
                                final y = int.tryParse(v);
                                if (y == null ||
                                    y < 2020 ||
                                    y > 2099) {
                                  return 'Thn tidak valid';
                                }
                                return null;
                              }),
                        ),
                      ],
                    ),

                    _buildField('Pagu Anggaran (Rp)', _paguCtrl,
                        hint: 'Contoh: 150000000',
                        inputType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        prefix: 'Rp '),

                    // Bidang
                    const SizedBox(height: 4),
                    const Text('Urusan / Bidang',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedBidang,
                      decoration: const InputDecoration(
                          hintText: '-- Pilih Urusan --'),
                      items: kBidangList
                          .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b,
                                  style: const TextStyle(
                                      fontSize: 13))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBidang = v),
                      validator: (v) =>
                          v == null ? 'Pilih urusan' : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: ap.isSaving
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: ap.isSaving ? null : _submit,
                    icon: ap.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(
                        ap.isSaving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    TextInputType? inputType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: inputType,
            inputFormatters: formatters,
            decoration: InputDecoration(
              hintText: hint ?? label,
              prefixText: prefix,
              prefixStyle:
                  const TextStyle(color: AppColors.textSecondary),
            ),
            validator: validator ??
                (v) => (v == null || v.trim().isEmpty)
                    ? '$label wajib diisi'
                    : null,
          ),
        ],
      ),
    );
  }
}