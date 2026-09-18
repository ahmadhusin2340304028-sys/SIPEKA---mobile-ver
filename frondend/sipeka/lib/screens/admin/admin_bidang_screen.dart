// lib/screens/admin/admin_bidang_screen.dart
//
// Halaman Admin untuk mengelola master data "Bidang". Data ini menjadi
// sumber dropdown/filter di fitur lain: Kelola Kegiatan, Kelola Undangan,
// Export Laporan, dan filter di halaman Kegiatan biasa.
//
// Setiap bidang bisa punya SATU akun staff utama (username & password)
// yang dikelola langsung dari form Tambah/Edit di sini. Menghapus bidang
// akan ikut menghapus seluruh kegiatan, undangan terkait, dan akun staff
// bidang tersebut — makanya proses hapus butuh 2 tahap konfirmasi.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/bidang_model.dart';
import '../../providers/bidang_provider.dart';
import '../../widgets/custom_drawer.dart';

class AdminBidangScreen extends StatefulWidget {
  const AdminBidangScreen({super.key});

  @override
  State<AdminBidangScreen> createState() => _AdminBidangScreenState();
}

class _AdminBidangScreenState extends State<AdminBidangScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BidangProvider>().loadBidang();
    });
  }

  void _showBidangDialog(BuildContext context, {BidangModel? bidang}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BidangDialog(bidang: bidang),
    );
  }

  // ─── Hapus bidang — 2 tahap konfirmasi ──────────────────────────────────

  Future<void> _confirmHapus(BuildContext context, BidangModel bidang) async {
    // Tahap 1: peringatan lengkap konsekuensi hapus.
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
          SizedBox(width: 8),
          Text('Hapus Bidang?'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bidang.nama,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 0.75),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tindakan ini TIDAK BISA DIBATALKAN. Menghapus bidang ini '
                      'akan ikut menghapus secara permanen:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8),
                    _HapusPoin(text: 'Seluruh data Kegiatan pada bidang ini — target, realisasi, bukti pendukung'),
                    _HapusPoin(text: 'Seluruh data Undangan yang menyertakan bidang ini'),
                    _HapusPoin(text: 'Akun login staff utama bidang ini (jika ada)'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (lanjut != true || !mounted) return;

    // Tahap 2: ketik ulang nama bidang untuk memastikan.
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _KonfirmasiHapusFinalDialog(namaBidang: bidang.nama),
    );

    if (confirmed != true || !mounted) return;

    final bp = context.read<BidangProvider>();
    final ok = await bp.hapusBidang(bidang.id);
    if (mounted) {
      if (ok) {
        AppUtils.showSuccess(context, bp.successMessage ?? 'Bidang berhasil dihapus');
      } else {
        AppUtils.showError(context, bp.errorMessage ?? 'Gagal menghapus bidang');
      }
      bp.clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BidangProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Bidang'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showBidangDialog(context),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Tambah Bidang',
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: bp.isLoading && bp.bidangList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : bp.bidangList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.apartment_rounded,
                          size: 56, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      const Text('Belum ada data bidang',
                          style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showBidangDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Tambah Bidang'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => bp.loadBidang(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 0.75),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 15, color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Daftar bidang ini dipakai sebagai pilihan dropdown '
                                'di fitur Kelola Kegiatan, Kelola Undangan, filter '
                                'Kegiatan, dan Export Laporan. Setiap bidang bisa '
                                'punya satu akun login staff utama.',
                                style: TextStyle(fontSize: 11.5, color: AppColors.primaryDark, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...bp.bidangList.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _BidangCard(
                            bidang: b,
                            onEdit: () => _showBidangDialog(context, bidang: b),
                            onHapus: () => _confirmHapus(context, b),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBidangDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _HapusPoin extends StatelessWidget {
  final String text;
  const _HapusPoin({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog konfirmasi akhir — admin wajib mengetik ulang nama bidang persis
/// sama sebelum tombol "Hapus Permanen" aktif. Ini tahap ke-2 dari 2
/// konfirmasi yang diminta untuk tindakan destruktif ini.
class _KonfirmasiHapusFinalDialog extends StatefulWidget {
  final String namaBidang;
  const _KonfirmasiHapusFinalDialog({required this.namaBidang});

  @override
  State<_KonfirmasiHapusFinalDialog> createState() =>
      _KonfirmasiHapusFinalDialogState();
}

class _KonfirmasiHapusFinalDialogState
    extends State<_KonfirmasiHapusFinalDialog> {
  final _ctrl = TextEditingController();

  bool get _valid => _ctrl.text.trim() == widget.namaBidang;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 22),
        SizedBox(width: 8),
        Text('Konfirmasi Akhir'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              children: [
                const TextSpan(text: 'Ketik '),
                TextSpan(
                  text: widget.namaBidang,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const TextSpan(
                    text: ' untuk memastikan Anda benar-benar ingin menghapusnya.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            onChanged: (_) => setState(() {}),
            autofocus: true,
            decoration: InputDecoration(hintText: widget.namaBidang),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _valid ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Hapus Permanen'),
        ),
      ],
    );
  }
}

// ─── Bidang Card ──────────────────────────────────────────────────────────────

class _BidangCard extends StatelessWidget {
  final BidangModel bidang;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const _BidangCard({
    required this.bidang,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.apartment_rounded, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bidang.nama,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (bidang.keterangan != null && bidang.keterangan!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      bidang.keterangan!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        bidang.hasAccount
                            ? Icons.verified_user_rounded
                            : Icons.person_off_rounded,
                        size: 12,
                        color: bidang.hasAccount ? AppColors.success : AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          bidang.hasAccount
                              ? 'Akun: ${bidang.username}'
                              : 'Belum ada akun staff',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: bidang.hasAccount ? FontWeight.w500 : FontWeight.w400,
                            color: bidang.hasAccount ? AppColors.success : AppColors.textHint,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onHapus,
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
              tooltip: 'Hapus',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bidang Dialog (tambah/edit) ──────────────────────────────────────────────

class _BidangDialog extends StatefulWidget {
  final BidangModel? bidang;
  const _BidangDialog({this.bidang});

  @override
  State<_BidangDialog> createState() => _BidangDialogState();
}

class _BidangDialogState extends State<_BidangDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _keteranganCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  bool _obscurePassword = true;

  bool get _isEdit => widget.bidang != null;
  bool get _hasExistingAccount => widget.bidang?.hasAccount ?? false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.bidang?.nama ?? '');
    _keteranganCtrl = TextEditingController(text: widget.bidang?.keterangan ?? '');
    _usernameCtrl = TextEditingController(text: widget.bidang?.username ?? '');
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _keteranganCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Validasi akun staff (opsional, tapi kalau salah satu diisi harus konsisten)
    if (username.isNotEmpty || password.isNotEmpty) {
      if (username.isEmpty) {
        AppUtils.showError(context, 'Username wajib diisi jika ingin mengatur akun staff.');
        return;
      }
      if (!_hasExistingAccount && password.isEmpty) {
        AppUtils.showError(context, 'Kata sandi wajib diisi untuk akun staff baru.');
        return;
      }
      if (password.isNotEmpty && password.length < 6) {
        AppUtils.showError(context, 'Kata sandi minimal 6 karakter.');
        return;
      }
    }

    FocusScope.of(context).unfocus();

    final bp = context.read<BidangProvider>();
    bool ok;
    if (_isEdit) {
      ok = await bp.editBidang(
        widget.bidang!.id,
        nama: _namaCtrl.text.trim(),
        keterangan: _keteranganCtrl.text.trim(),
        username: username.isEmpty ? null : username,
        password: password.isEmpty ? null : password,
      );
    } else {
      ok = await bp.tambahBidang(
        nama: _namaCtrl.text.trim(),
        keterangan: _keteranganCtrl.text.trim(),
        username: username.isEmpty ? null : username,
        password: password.isEmpty ? null : password,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      AppUtils.showSuccess(context, bp.successMessage ?? 'Berhasil disimpan');
      bp.clearMessages();
    } else {
      AppUtils.showError(context, bp.errorMessage ?? 'Gagal menyimpan');
      bp.clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BidangProvider>();

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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.apartment_rounded, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Bidang' : 'Tambah Bidang',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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
                    const Text('Nama Bidang',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaCtrl,
                      decoration: const InputDecoration(hintText: 'Contoh: Rehabilitasi Sosial'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nama bidang wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Keterangan (opsional)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _keteranganCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Deskripsi singkat bidang ini'),
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 0),
                    const SizedBox(height: 16),

                    // ── Akun Staff Bidang ──────────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.badge_rounded, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        const Text('Akun Staff Bidang',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hasExistingAccount
                          ? 'Bidang ini sudah punya akun staff. Ubah username/kata sandi di bawah kalau perlu.'
                          : 'Opsional — isi untuk langsung membuat akun login staff utama bidang ini.',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.4),
                    ),
                    const SizedBox(height: 10),

                    const Text('Username',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(hintText: 'Contoh: staff_perencanaan'),
                    ),
                    const SizedBox(height: 14),

                    const Text('Kata Sandi',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: _hasExistingAccount
                            ? 'Kosongkan jika tidak ingin mengubah'
                            : 'Minimal 6 karakter',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A), width: 0.75),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mengubah nama bidang otomatis memperbarui kegiatan & undangan '
                              'yang memakai bidang ini. Beberapa bidang bawaan tidak dapat '
                              'diganti namanya karena masih terhubung ke akun jabatan struktural lama.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    onPressed: bp.isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: bp.isSaving ? null : _submit,
                    icon: bp.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(bp.isSaving ? 'Menyimpan...' : 'Simpan'),
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
