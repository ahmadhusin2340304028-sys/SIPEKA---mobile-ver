// lib/screens/admin/admin_undangan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_drawer.dart';

// Semua role yang bisa diundang (sesuai BIDANG_ROLE_MAP di User.php)
const List<String> kPihakTerkaitList = [
  'Kepala Dinas',
  'Kepala Bidang Pemberdayaan Masyarakat',
  'Kepala Bidang Sosial',
  'Kepala Sub Bagian Perencanaan',
  'Kepala Sub Bagian Kepegawaian',
  'Sekretaris',
  'Perencanaan dan Keuangan',
  'Umum dan Kepegawaian',
  'Rehabilitasi Sosial',
  'Perlindungan dan Jaminan Sosial',
  'Pemberdayaan Sosial',
  'Pemberdayaan Masyarakat',
];

const List<String> kBidangUndangan = [
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
                      const Icon(Icons.mail_outline_rounded, size: 56, color: AppColors.textHint),
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

  Future<void> _confirmHapus(BuildContext context, Map<String, dynamic> u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
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
                u['judul_kegiatan'] ?? '-',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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
          AppUtils.showError(context, ap.errorMessage ?? 'Gagal menghapus');
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

  String get _statusLabel => data['status_kegiatan'] ?? '-';
  bool get _isSelesai => _statusLabel == 'Sudah Dilaksanakan';

  Color get _statusColor => _isSelesai ? AppColors.success : AppColors.warning;
  Color get _statusBg => _isSelesai ? AppColors.successLight : AppColors.warningLight;

  @override
  Widget build(BuildContext context) {
    final tanggal = data['tanggal']?.toString() ?? '-';
    final waktu = data['waktu']?.toString() ?? '-';
    final tempat = data['tempat']?.toString() ?? '-';
    final mengundang = data['pihak_mengundang']?.toString() ?? '-';
    final bidang = data['bidang_terkait']?.toString() ?? '-';
    final menghadiri = data['menghadiri']?.toString() ?? 'Pending';

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
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    data['judul_kegiatan']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isSelesai ? 'Selesai' : 'Belum',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(Icons.calendar_today_rounded, '$tanggal · $waktu WIB'),
                const SizedBox(height: 4),
                _MetaRow(Icons.location_on_outlined, tempat),
                const SizedBox(height: 4),
                _MetaRow(Icons.business_rounded, mengundang),
                const SizedBox(height: 4),
                _MetaRow(Icons.domain_rounded, 'Bidang: $bidang'),
                const SizedBox(height: 4),
                _MetaRow(
                  Icons.how_to_reg_rounded,
                  'Kehadiran: $menghadiri',
                  color: _menghadiriColor(menghadiri),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onHapus,
                  icon: const Icon(Icons.delete_outline_rounded, size: 15),
                  label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Color _menghadiriColor(String s) {
    switch (s) {
      case 'Hadir': return AppColors.success;
      case 'Tidak Hadir': return AppColors.danger;
      default: return AppColors.warning;
    }
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _MetaRow(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: c)),
        ),
      ],
    );
  }
}

// ─── Undangan Dialog ──────────────────────────────────────────────────────────

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
  late final TextEditingController _delegasiCtrl;

  DateTime? _tanggal;
  TimeOfDay? _waktu;
  String? _selectedBidang;
  String _statusKegiatan = 'Belum Dilaksanakan';
  String _menghadiri = 'Pending';

  // Multi-select pihak terkait
  final Set<String> _selectedPihak = {};

  bool get _isEdit => widget.data != null;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _judulCtrl = TextEditingController(text: d?['judul_kegiatan']?.toString() ?? '');
    _tempatCtrl = TextEditingController(text: d?['tempat']?.toString() ?? '');
    _mengundangCtrl = TextEditingController(text: d?['pihak_mengundang']?.toString() ?? '');
    _delegasiCtrl = TextEditingController(text: d?['delegasi']?.toString() ?? '');

    if (d != null) {
      final tgl = d['tanggal']?.toString();
      if (tgl != null) _tanggal = DateTime.tryParse(tgl);

      final wkt = d['waktu']?.toString();
      if (wkt != null) {
        final parts = wkt.split(':');
        if (parts.length >= 2) {
          _waktu = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
        }
      }

      _selectedBidang = d['bidang_terkait']?.toString();
      if (_selectedBidang != null && !kBidangUndangan.contains(_selectedBidang)) _selectedBidang = null;
      _statusKegiatan = d['status_kegiatan']?.toString() ?? 'Belum Dilaksanakan';
      _menghadiri = d['menghadiri']?.toString() ?? 'Pending';
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _tempatCtrl.dispose();
    _mengundangCtrl.dispose();
    _delegasiCtrl.dispose();
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
    if (_tanggal == null) { AppUtils.showError(context, 'Pilih tanggal kegiatan.'); return; }
    if (_waktu == null) { AppUtils.showError(context, 'Pilih waktu kegiatan.'); return; }
    if (_selectedBidang == null) { AppUtils.showError(context, 'Pilih bidang terkait.'); return; }

    FocusScope.of(context).unfocus();

    final h = _waktu!.hour.toString().padLeft(2, '0');
    final m = _waktu!.minute.toString().padLeft(2, '0');

    final ap = context.read<AdminProvider>();
    final data = {
      'judul_kegiatan': _judulCtrl.text.trim(),
      'tanggal': '${_tanggal!.year}-${_tanggal!.month.toString().padLeft(2,'0')}-${_tanggal!.day.toString().padLeft(2,'0')}',
      'waktu': '$h:$m',
      'tempat': _tempatCtrl.text.trim(),
      'pihak_mengundang': _mengundangCtrl.text.trim(),
      'bidang_terkait': _selectedBidang,
      'status_kegiatan': _statusKegiatan,
      'menghadiri': _menghadiri,
      if (_delegasiCtrl.text.trim().isNotEmpty) 'delegasi': _delegasiCtrl.text.trim(),
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
      AppUtils.showSuccess(context, ap.successMessage ?? 'Berhasil disimpan');
      ap.clearMessages();
    } else {
      AppUtils.showError(context, ap.errorMessage ?? 'Gagal menyimpan');
      ap.clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.mail_rounded, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Undangan' : 'Tambah Surat Undangan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
                    // Judul Kegiatan
                    _label('Kegiatan'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _judulCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Nama / judul kegiatan undangan'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    // Tanggal | Waktu | Tempat
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Tanggal'),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _pickTanggal,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceGray,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border, width: 0.75),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        _tanggal != null
                                            ? '${_tanggal!.day.toString().padLeft(2,'0')}/${_tanggal!.month.toString().padLeft(2,'0')}/${_tanggal!.year}'
                                            : 'dd/mm/yyyy',
                                        style: TextStyle(fontSize: 12,
                                            color: _tanggal != null ? AppColors.textPrimary : AppColors.textHint),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Waktu'),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _pickWaktu,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceGray,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border, width: 0.75),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        _waktu != null
                                            ? '${_waktu!.hour.toString().padLeft(2,'0')}:${_waktu!.minute.toString().padLeft(2,'0')}'
                                            : '--:--',
                                        style: TextStyle(fontSize: 12,
                                            color: _waktu != null ? AppColors.textPrimary : AppColors.textHint),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _label('Tempat'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tempatCtrl,
                      decoration: const InputDecoration(hintText: 'Ruang / Lokasi kegiatan'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    // Status Kegiatan
                    _label('Status Kegiatan'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _statusKegiatan,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'Belum Dilaksanakan', child: Text('Belum Terlaksana', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Sudah Dilaksanakan', child: Text('Sudah Dilaksanakan', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) => setState(() => _statusKegiatan = v ?? _statusKegiatan),
                    ),
                    const SizedBox(height: 14),

                    // Menghadiri
                    _label('Kehadiran'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _menghadiri,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Hadir', child: Text('Hadir', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Tidak Hadir', child: Text('Tidak Hadir', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Delegasi', child: Text('Delegasi', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) => setState(() => _menghadiri = v ?? _menghadiri),
                    ),
                    const SizedBox(height: 14),

                    // Pihak Mengundang
                    _label('Pihak Yang Mengundang'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _mengundangCtrl,
                      decoration: const InputDecoration(hintText: 'Instansi / pihak pengundang'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    // Bidang Terkait
                    _label('Bidang Terkait'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedBidang,
                      decoration: const InputDecoration(hintText: '-- Pilih Bidang --'),
                      items: kBidangUndangan
                          .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBidang = v),
                      validator: (v) => v == null ? 'Pilih bidang' : null,
                    ),
                    const SizedBox(height: 14),

                    // Pihak yang Terkait / Diundang (multi-select checkboxes)
                    _label('Pihak Yang Terkait/diundang'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, width: 0.75),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.surfaceGray,
                      ),
                      child: Column(
                        children: List.generate(kPihakTerkaitList.length, (i) {
                          final item = kPihakTerkaitList[i];
                          final isLast = i == kPihakTerkaitList.length - 1;
                          return Column(
                            children: [
                              CheckboxListTile(
                                value: _selectedPihak.contains(item),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedPihak.add(item);
                                    } else {
                                      _selectedPihak.remove(item);
                                    }
                                  });
                                },
                                title: Text(item, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                activeColor: AppColors.primary,
                              ),
                              if (!isLast) const Divider(height: 0, indent: 8, endIndent: 8),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Delegasi (opsional)
                    _label('Delegasi (opsional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _delegasiCtrl,
                      decoration: const InputDecoration(hintText: 'Nama delegasi jika ada'),
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
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: ap.isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: ap.isSaving ? null : _submit,
                    icon: ap.isSaving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(ap.isSaving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary));
}