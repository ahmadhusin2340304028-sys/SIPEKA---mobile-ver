// lib/screens/admin/admin_undangan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_drawer.dart';

/// Semua pihak yang bisa diundang (sesuai BIDANG_ROLE_MAP di User.php)
const List<String> kPihakTerkaitList = [
  'Kepala Dinas',
  'Sekretaris',
  'Kepala Bidang Sosial',
  'Kepala Bidang Pemberdayaan Masyarakat',
  'Kepala Sub Bagian Perencanaan',
  'Kepala Sub Bagian Kepegawaian',
  'Perencanaan dan Keuangan',
  'Umum dan Kepegawaian',
  'Rehabilitasi Sosial',
  'Perlindungan dan Jaminan Sosial',
  'Pemberdayaan Sosial',
  'Pemberdayaan Masyarakat',
];

class AdminUndanganScreen extends StatefulWidget {
  const AdminUndanganScreen({super.key});

  @override
  State<AdminUndanganScreen> createState() => _AdminUndanganScreenState();
}

class _AdminUndanganScreenState extends State<AdminUndanganScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUndangan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Undangan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showUndanganDialog(context),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Tambah Undangan',
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: ap.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ap.undanganList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mail_outline_rounded,
                          size: 56, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      const Text('Belum ada data undangan',
                          style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showUndanganDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Tambah Undangan'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: ap.loadUndangan,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: ap.undanganList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final u = ap.undanganList[i];
                      return _UndanganAdminCard(
                        data: u,
                        onEdit: () => _showUndanganDialog(context, data: u),
                        onHapus: () => _confirmHapus(context, u),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUndanganDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showUndanganDialog(BuildContext context, {Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UndanganDialog(data: data),
    );
  }

  Future<void> _confirmHapus(
      BuildContext context, Map<String, dynamic> u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const Text('Hapus undangan berikut?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                u['judul_kegiatan']?.toString() ?? '-',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
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
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ap = context.read<AdminProvider>();
      final ok = await ap.hapusUndangan(u['id'] as int);
      if (mounted) {
        if (ok) {
          AppUtils.showSuccess(context, 'Undangan berhasil dihapus');
        } else {
          AppUtils.showError(
              context, ap.errorMessage ?? 'Gagal menghapus');
        }
        ap.clearMessages();
      }
    }
  }
}

// ─── Undangan Admin Card ──────────────────────────────────────────────────────

class _UndanganAdminCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const _UndanganAdminCard({
    required this.data,
    required this.onEdit,
    required this.onHapus,
  });

  /// Parse bidang_terkait (comma-separated string) ke list
  List<String> get _pihakList {
    final raw = data['bidang_terkait']?.toString() ?? '';
    if (raw.isEmpty) return [];
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  String get _menghadiriLabel => data['menghadiri']?.toString() ?? 'Pending';

  Color _menghadiriColor(String s) {
    final lower = s.toLowerCase();
    if (lower == 'tidak hadir') return AppColors.danger;
    if (lower == 'pending') return AppColors.warning;
    // Hadir atau nama bidang/username (berarti sudah hadir)
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final tanggalRaw = data['tanggal']?.toString() ?? '';
    final tanggalDt = DateTime.tryParse(tanggalRaw);
    final tanggal = tanggalDt != null ? AppUtils.formatDate(tanggalDt) : (tanggalRaw.isNotEmpty ? tanggalRaw : '-');
    final waktuRaw = data['waktu']?.toString() ?? '';
    final waktu = waktuRaw.length >= 5
        ? waktuRaw.substring(0, 5)
        : (waktuRaw.isNotEmpty ? waktuRaw : '-');
    final tempat = data['tempat']?.toString() ?? '-';
    final mengundang = data['pihak_mengundang']?.toString() ?? '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: judul ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceGray,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                  bottom:
                      BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Text(
              data['judul_kegiatan']?.toString() ?? '-',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Info ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(Icons.calendar_today_rounded,
                    '$tanggal · $waktu WIB'),
                const SizedBox(height: 4),
                _MetaRow(Icons.location_on_outlined, tempat),
                const SizedBox(height: 4),
                _MetaRow(Icons.business_rounded, mengundang),
                const SizedBox(height: 6),

                // Pihak yang diundang (badges)
                if (_pihakList.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.groups_rounded,
                          size: 13, color: AppColors.textMuted),
                      SizedBox(width: 6),
                      Text(
                        'Pihak yang diundang:',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _pihakList
                        .map((p) => _PihakChip(label: p))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                ],

                // Status kehadiran (read-only, diisi oleh user)
                const Divider(height: 12),
                Row(
                  children: [
                    const Icon(Icons.how_to_reg_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    const Text('Kehadiran: ',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    Text(
                      _menghadiriLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _menghadiriColor(_menghadiriLabel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── Actions ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label:
                      const Text('Edit', style: TextStyle(fontSize: 12)),
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

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
        ),
      ],
    );
  }
}

class _PihakChip extends StatelessWidget {
  final String label;
  const _PihakChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

// ─── Undangan Dialog ──────────────────────────────────────────────────────────
//
// Admin hanya mengisi:
//   judul_kegiatan, tanggal, waktu, tempat, pihak_mengundang, bidang_terkait
//
// Field menghadiri, bukti, delegasi diisi oleh user masing-masing (bukan admin).

class _UndanganDialog extends StatefulWidget {
  final Map<String, dynamic>? data;
  const _UndanganDialog({this.data});

  @override
  State<_UndanganDialog> createState() => _UndanganDialogState();
}

class _UndanganDialogState extends State<_UndanganDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _judulCtrl;
  late final TextEditingController _tempatCtrl;
  late final TextEditingController _mengundangCtrl;

  DateTime? _tanggal;
  TimeOfDay? _waktu;

  /// Multi-select: pihak yang diundang
  final Set<String> _selectedPihak = {};

  bool get _isEdit => widget.data != null;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _judulCtrl =
        TextEditingController(text: d?['judul_kegiatan']?.toString() ?? '');
    _tempatCtrl =
        TextEditingController(text: d?['tempat']?.toString() ?? '');
    _mengundangCtrl =
        TextEditingController(text: d?['pihak_mengundang']?.toString() ?? '');

    if (d != null) {
      // Parse tanggal
      final tgl = d['tanggal']?.toString();
      if (tgl != null) _tanggal = DateTime.tryParse(tgl);

      // Parse waktu
      final wkt = d['waktu']?.toString() ?? '';
      if (wkt.isNotEmpty) {
        final parts = wkt.split(':');
        if (parts.length >= 2) {
          _waktu = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }

      // Parse bidang_terkait → isi _selectedPihak
      final bidang = d['bidang_terkait']?.toString() ?? '';
      if (bidang.isNotEmpty) {
        _selectedPihak.addAll(
          bidang
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty),
        );
      }
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _tempatCtrl.dispose();
    _mengundangCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTanggal() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (d != null) setState(() => _tanggal = d);
  }

  Future<void> _pickWaktu() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _waktu ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _waktu = t);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tanggal == null) {
      AppUtils.showError(context, 'Pilih tanggal kegiatan.');
      return;
    }
    if (_waktu == null) {
      AppUtils.showError(context, 'Pilih waktu kegiatan.');
      return;
    }
    if (_selectedPihak.isEmpty) {
      AppUtils.showError(context, 'Pilih minimal satu pihak yang diundang.');
      return;
    }

    FocusScope.of(context).unfocus();

    final h = _waktu!.hour.toString().padLeft(2, '0');
    final m = _waktu!.minute.toString().padLeft(2, '0');

    // bidang_terkait dikirim sebagai List (array) agar backend bisa parse
    final bidangList = _selectedPihak.toList();

    final ap = context.read<AdminProvider>();
    final data = {
      'judul_kegiatan': _judulCtrl.text.trim(),
      'tanggal':
          '${_tanggal!.year}-${_tanggal!.month.toString().padLeft(2, '0')}-${_tanggal!.day.toString().padLeft(2, '0')}',
      'waktu': '$h:$m',
      'tempat': _tempatCtrl.text.trim(),
      'pihak_mengundang': _mengundangCtrl.text.trim(),
      'bidang_terkait': bidangList,  // array → backend akan join dengan ", "
    };

    bool ok;
    if (_isEdit) {
      ok = await ap.editUndangan(widget.data!['id'] as int, data);
    } else {
      ok = await ap.tambahUndangan(data);
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      AppUtils.showSuccess(
          context, ap.successMessage ?? 'Undangan berhasil disimpan.');
      ap.clearMessages();
    } else {
      AppUtils.showError(
          context, ap.errorMessage ?? 'Gagal menyimpan undangan.');
      ap.clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5)),
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
                  child: const Icon(Icons.mail_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Undangan' : 'Tambah Surat Undangan',
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

          // ── Form ───────────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul Kegiatan
                    _label('Judul / Nama Kegiatan'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _judulCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Nama / judul kegiatan undangan'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Tanggal & Waktu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Tanggal'),
                              const SizedBox(height: 6),
                              _DatePickerField(
                                date: _tanggal,
                                onTap: _pickTanggal,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Waktu'),
                              const SizedBox(height: 6),
                              _TimePickerField(
                                time: _waktu,
                                onTap: _pickWaktu,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tempat
                    _label('Tempat'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tempatCtrl,
                      decoration: const InputDecoration(
                          hintText: 'Ruang / lokasi kegiatan'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Pihak Mengundang
                    _label('Pihak yang Mengundang'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _mengundangCtrl,
                      decoration: const InputDecoration(
                          hintText: 'Instansi / pihak pengundang'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Pihak yang Diundang (multi-select checkbox)
                    _label('Pihak yang Diundang'),
                    const SizedBox(height: 4),
                    const Text(
                      'Pilih satu atau lebih pihak yang akan menerima undangan',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 8),

                    // Tampilkan badge pihak terpilih
                    if (_selectedPihak.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _selectedPihak
                            .map((p) => Chip(
                                  label: Text(p,
                                      style: const TextStyle(fontSize: 11)),
                                  deleteIcon: const Icon(
                                      Icons.close_rounded,
                                      size: 14),
                                  onDeleted: () =>
                                      setState(() => _selectedPihak.remove(p)),
                                  backgroundColor: AppColors.primaryLight,
                                  labelStyle: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 11),
                                  side: const BorderSide(
                                      color: Color(0xFFBFDBFE), width: 0.5),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Daftar checkbox pihak
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.border, width: 0.75),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.surfaceGray,
                      ),
                      child: Column(
                        children: List.generate(
                          kPihakTerkaitList.length,
                          (i) {
                            final item = kPihakTerkaitList[i];
                            final isLast =
                                i == kPihakTerkaitList.length - 1;
                            final isChecked =
                                _selectedPihak.contains(item);
                            return Column(
                              children: [
                                CheckboxListTile(
                                  value: isChecked,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedPihak.add(item);
                                      } else {
                                        _selectedPihak.remove(item);
                                      }
                                    });
                                  },
                                  title: Text(item,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8),
                                  activeColor: AppColors.primary,
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(
                                      height: 0,
                                      indent: 8,
                                      endIndent: 8),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Info: field lain diisi oleh user
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFFDE68A), width: 0.75),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.warning),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Konfirmasi kehadiran (hadir/tidak hadir), bukti, dan delegasi diisi oleh masing-masing pihak yang diundang.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        ap.isSaving ? null : () => Navigator.pop(context),
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(ap.isSaving
                        ? 'Menyimpan...'
                        : (_isEdit ? 'Simpan Perubahan' : 'Simpan')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary),
      );
}

// ─── Date & Time Picker Field Widgets ────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;
  const _DatePickerField({required this.date, required this.onTap});

  String get _label {
    if (date == null) return 'dd/mm/yyyy';
    return '${date!.day.toString().padLeft(2, '0')}/'
        '${date!.month.toString().padLeft(2, '0')}/'
        '${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.75),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                color: date != null
                    ? AppColors.textPrimary
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final TimeOfDay? time;
  final VoidCallback onTap;
  const _TimePickerField({required this.time, required this.onTap});

  String get _label {
    if (time == null) return '--:--';
    return '${time!.hour.toString().padLeft(2, '0')}:'
        '${time!.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.75),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                color: time != null
                    ? AppColors.textPrimary
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}