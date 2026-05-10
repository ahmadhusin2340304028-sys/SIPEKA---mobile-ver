// lib/screens/undangan/undangan_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/undangan_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/undangan_provider.dart';
import '../../widgets/custom_drawer.dart';

class UndanganScreen extends StatefulWidget {
  const UndanganScreen({super.key});

  @override
  State<UndanganScreen> createState() => _UndanganScreenState();
}

class _UndanganScreenState extends State<UndanganScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UndanganProvider>().loadUndangan();
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      context.read<UndanganProvider>().loadMoreUndangan();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UndanganProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.undangan),
        actions: [
          if (up.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${up.pendingCount} pending',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // ── Filter Bar ──────────────────────────────────────────────────
          _FilterBar(selected: up.filterStatus, onSelect: up.setFilter),
          const Divider(height: 0),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: up.isLoading
                ? const Center(child: CircularProgressIndicator())
                : up.errorMessage != null
                    ? _ErrorState(
                        message: up.errorMessage!,
                        onRetry: up.loadUndangan,
                      )
                    : up.filteredUndangan.isEmpty
                        ? _EmptyState(filter: up.filterStatus)
                        : RefreshIndicator(
                            onRefresh: up.loadUndangan,
                            child: ListView.separated(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.all(16),
                              itemCount: up.filteredUndangan.length +
                                  (up.isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                // Loading indicator di item terakhir
                                if (i >= up.filteredUndangan.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }
                                final u = up.filteredUndangan[i];
                                return _UndanganCard(
                                  undangan: u,
                                  isUpdating: up.isUpdating,
                                  onHadiri: () => _showHadiriDialog(context, up, u),
                                  onTidakHadir: () =>
                                      _showTidakHadirDialog(context, up, u),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ─── Dialog: Konfirmasi Hadir ──────────────────────────────────────────────

  Future<void> _showHadiriDialog(
    BuildContext context,
    UndanganProvider up,
    UndanganModel undangan,
  ) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    // Identitas yang akan otomatis tercatat sebagai "menghadiri"
    final identitasHadir = user?.bidang?.isNotEmpty == true
        ? user!.bidang!
        : user?.username ?? '-';

    bool isDelegasi = false;
    final delegasiCtrl = TextEditingController();
    PlatformFile? selectedBukti;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Konfirmasi Kehadiran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Judul undangan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGray,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Text(
                      undangan.judul,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Info menghadiri (otomatis)
                  _DialogInfoRow(
                    label: 'Dihadiri oleh',
                    value: identitasHadir,
                    icon: Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),

                  // Checkbox delegasi
                  GestureDetector(
                    onTap: () => setS(() => isDelegasi = !isDelegasi),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDelegasi ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDelegasi ? AppColors.primary : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: isDelegasi
                              ? const Icon(Icons.check_rounded,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Hadir sebagai delegasi',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Textarea delegasi (muncul kalau checkbox dicentang)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: isDelegasi
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              const Text(
                                'Keterangan delegasi',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: delegasiCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Contoh: perwakilan/delegasi kepala dinas',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 14),

                  // Upload bukti
                  const Text(
                    'Bukti kehadiran (opsional)',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        if (result.files.single.size > 5 * 1024 * 1024) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('File maksimal 5 MB'),
                            ));
                          }
                          return;
                        }
                        setS(() => selectedBukti = result.files.single);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGray,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedBukti != null
                              ? AppColors.success
                              : AppColors.border,
                          width: selectedBukti != null ? 1 : 0.75,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedBukti != null
                                ? Icons.check_circle_rounded
                                : Icons.attach_file_rounded,
                            size: 18,
                            color: selectedBukti != null
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedBukti?.name ?? 'Pilih file bukti...',
                              style: TextStyle(
                                fontSize: 12,
                                color: selectedBukti != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selectedBukti != null)
                            GestureDetector(
                              onTap: () => setS(() => selectedBukti = null),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol aksi
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Konfirmasi'),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await up.konfirmasiHadir(
        id: undangan.id,
        delegasi: isDelegasi && delegasiCtrl.text.trim().isNotEmpty
            ? delegasiCtrl.text.trim()
            : null,
        buktiBytes: selectedBukti?.bytes != null
            ? List<int>.from(selectedBukti!.bytes!)
            : null,
        buktiFileName: selectedBukti?.name,
      );

      if (context.mounted) {
        if (ok) {
          AppUtils.showSuccess(
              context, up.lastMessage ?? 'Kehadiran berhasil dikonfirmasi.');
        } else {
          AppUtils.showError(
              context, up.errorMessage ?? 'Gagal mengonfirmasi kehadiran.');
        }
        up.clearMessage();
      }
    }

    delegasiCtrl.dispose();
  }

  // ─── Dialog: Tidak Hadir ──────────────────────────────────────────────────

  Future<void> _showTidakHadirDialog(
    BuildContext context,
    UndanganProvider up,
    UndanganModel undangan,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text('Tidak Dapat Hadir'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${undangan.judul}"',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Konfirmasi bahwa Anda tidak dapat hadir dalam undangan ini.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Konfirmasi'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await up.tandaiTidakHadir(id: undangan.id);
      if (context.mounted) {
        if (ok) {
          AppUtils.showInfo(
              context, up.lastMessage ?? 'Undangan ditandai tidak hadir.');
        } else {
          AppUtils.showError(
              context, up.errorMessage ?? 'Gagal memperbarui status.');
        }
        up.clearMessage();
      }
    }
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final StatusUndangan? selected;
  final ValueChanged<StatusUndangan?> onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: 'Semua',
              isSelected: selected == null,
              onTap: () => onSelect(null),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Pending',
              isSelected: selected == StatusUndangan.pending,
              onTap: () => onSelect(StatusUndangan.pending),
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Hadir',
              isSelected: selected == StatusUndangan.hadir,
              onTap: () => onSelect(StatusUndangan.hadir),
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Tidak Hadir',
              isSelected: selected == StatusUndangan.tidakHadir,
              onTap: () => onSelect(StatusUndangan.tidakHadir),
              color: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Undangan Card ────────────────────────────────────────────────────────────

class _UndanganCard extends StatelessWidget {
  final UndanganModel undangan;
  final bool isUpdating;
  final VoidCallback onHadiri;
  final VoidCallback onTidakHadir;

  const _UndanganCard({
    required this.undangan,
    required this.isUpdating,
    required this.onHadiri,
    required this.onTidakHadir,
  });

  @override
  Widget build(BuildContext context) {
    final isPast =
        undangan.tanggal.isBefore(DateTime.now().subtract(const Duration(hours: 1)));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Accent line atas berdasar status ──────────────────────────
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _statusColor(undangan.status),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
          ),

          // ── Header: judul + badge ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    undangan.judul,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: undangan.status),
              ],
            ),
          ),

          // ── Meta Info ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanggal + Waktu
                _MetaRow(
                  icon: Icons.calendar_today_rounded,
                  text:
                      '${AppUtils.formatDate(undangan.tanggal)} · ${undangan.waktu} WIB',
                  highlight: isPast && undangan.status == StatusUndangan.pending,
                  highlightColor: AppColors.danger,
                ),
                const SizedBox(height: 5),
                // Tempat
                _MetaRow(
                  icon: Icons.location_on_outlined,
                  text: undangan.tempat,
                ),
                const SizedBox(height: 5),
                // Pihak mengundang
                _MetaRow(
                  icon: Icons.business_rounded,
                  text: undangan.pihakMengundang,
                ),
                const SizedBox(height: 8),

                // Pihak terkait (yang diundang — bisa banyak)
                _PihakTerkaitRow(pihakList: undangan.pihakTerkait),
                const SizedBox(height: 8),

                // Divider
                const Divider(height: 0),
                const SizedBox(height: 8),

                // Info kehadiran (jika sudah hadir)
                if (undangan.status == StatusUndangan.hadir) ...[
                  _InfoHadir(undangan: undangan),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),

          // ── Action Area ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
            child: _ActionArea(
              status: undangan.status,
              isUpdating: isUpdating,
              canRespond: undangan.canRespond,
              onHadiri: onHadiri,
              onTidakHadir: onTidakHadir,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(StatusUndangan s) {
    switch (s) {
      case StatusUndangan.hadir:
        return AppColors.success;
      case StatusUndangan.tidakHadir:
        return AppColors.danger;
      case StatusUndangan.pending:
        return AppColors.warning;
    }
  }
}

// ─── Info Hadir (tampil ketika sudah hadir) ───────────────────────────────────

class _InfoHadir extends StatelessWidget {
  final UndanganModel undangan;
  const _InfoHadir({required this.undangan});

  Future<void> _openBukti(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dihadiri oleh
          if (undangan.menghadiri != null && undangan.menghadiri!.isNotEmpty)
            _InfoHadirRow(
              icon: Icons.person_rounded,
              label: 'Dihadiri oleh',
              value: undangan.menghadiri!,
            ),

          // Delegasi
          if (undangan.delegasi != null && undangan.delegasi!.isNotEmpty) ...[
            const SizedBox(height: 5),
            _InfoHadirRow(
              icon: Icons.swap_horiz_rounded,
              label: 'Delegasi',
              value: undangan.delegasi!,
            ),
          ],

          // Bukti
          if (undangan.buktiUrl != null && undangan.buktiUrl!.isNotEmpty) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _openBukti(context, undangan.buktiUrl!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file_rounded,
                      size: 13, color: AppColors.success),
                  const SizedBox(width: 5),
                  const Text(
                    'lihat bukti',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoHadirRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoHadirRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF166534)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF166534)),
          ),
        ),
      ],
    );
  }
}

// ─── Pihak Terkait ────────────────────────────────────────────────────────────

class _PihakTerkaitRow extends StatelessWidget {
  final List<String> pihakList;
  const _PihakTerkaitRow({required this.pihakList});

  @override
  Widget build(BuildContext context) {
    if (pihakList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.groups_rounded, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 6),
            const Text(
              'Pihak yang diundang:',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: pihakList
              .map((p) => _PihakChip(label: p))
              .toList(),
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
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

// ─── Meta Row ────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  final Color? highlightColor;
  final Color? color;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.highlight = false,
    this.highlightColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = highlight
        ? (highlightColor ?? AppColors.danger)
        : color ?? AppColors.textMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: textColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: highlight ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Action Area ──────────────────────────────────────────────────────────────

class _ActionArea extends StatelessWidget {
  final StatusUndangan status;
  final bool isUpdating;
  final bool canRespond;
  final VoidCallback onHadiri;
  final VoidCallback onTidakHadir;

  const _ActionArea({
    required this.status,
    required this.isUpdating,
    required this.canRespond,
    required this.onHadiri,
    required this.onTidakHadir,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case StatusUndangan.hadir:
        return const Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
            SizedBox(width: 6),
            Text(
              'Kehadiran telah dikonfirmasi',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500),
            ),
          ],
        );

      case StatusUndangan.tidakHadir:
        return const Row(
          children: [
            Icon(Icons.cancel_rounded, size: 15, color: AppColors.danger),
            SizedBox(width: 6),
            Text(
              'Tidak dapat hadir',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500),
            ),
          ],
        );

      case StatusUndangan.pending:
        if (!canRespond) {
          return const Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hanya lihat undangan bidang lain',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isUpdating ? null : onHadiri,
                icon: const Icon(Icons.check_rounded, size: 15),
                label:
                    const Text('Hadir', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isUpdating ? null : onTidakHadir,
                icon: const Icon(Icons.close_rounded, size: 15),
                label: const Text('Tidak Hadir',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ],
        );
    }
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final StatusUndangan status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    IconData icon;

    switch (status) {
      case StatusUndangan.hadir:
        bg = AppColors.successLight;
        fg = const Color(0xFF166534);
        label = 'Hadir';
        icon = Icons.check_circle_rounded;
        break;
      case StatusUndangan.tidakHadir:
        bg = AppColors.dangerLight;
        fg = const Color(0xFF991B1B);
        label = 'Tidak Hadir';
        icon = Icons.cancel_rounded;
        break;
      case StatusUndangan.pending:
        bg = AppColors.warningLight;
        fg = const Color(0xFF92400E);
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Info Row helper ───────────────────────────────────────────────────

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DialogInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 0.75),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: color.withOpacity(0.7))),
              Text(
                value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final StatusUndangan? filter;
  const _EmptyState({this.filter});

  String get _message {
    switch (filter) {
      case StatusUndangan.hadir:
        return 'Belum ada undangan yang dikonfirmasi hadir';
      case StatusUndangan.tidakHadir:
        return 'Belum ada undangan yang tidak hadir';
      case StatusUndangan.pending:
        return 'Tidak ada undangan yang pending';
      default:
        return 'Belum ada undangan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mail_outline_rounded,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 14),
          Text(_message,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
