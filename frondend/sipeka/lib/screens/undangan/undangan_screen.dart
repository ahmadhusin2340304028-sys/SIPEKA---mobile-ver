// lib/screens/undangan/undangan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/undangan_model.dart';
import '../../providers/undangan_provider.dart';
import '../../widgets/custom_drawer.dart';

class UndanganScreen extends StatefulWidget {
  const UndanganScreen({super.key});

  @override
  State<UndanganScreen> createState() => _UndanganScreenState();
}

class _UndanganScreenState extends State<UndanganScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final up = context.read<UndanganProvider>();
      if (up.allUndangan.isEmpty) up.loadUndangan();
    });
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${up.pendingCount} pending',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
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
          _FilterBar(
            selected: up.filterStatus,
            onSelect: up.setFilter,
          ),
          const Divider(height: 0),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: up.isLoading
                ? const Center(child: CircularProgressIndicator())
                : up.filteredUndangan.isEmpty
                    ? _EmptyState(filter: up.filterStatus)
                    : RefreshIndicator(
                        onRefresh: up.loadUndangan,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: up.filteredUndangan.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final u = up.filteredUndangan[i];
                            return _UndanganCard(
                              undangan: u,
                              isUpdating: up.isUpdating,
                              onHadiri: () =>
                                  _showHadiriDialog(context, up, u),
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

  // ─── Dialogs ─────────────────────────────────────────────────────────────

  Future<void> _showHadiriDialog(
    BuildContext context,
    UndanganProvider up,
    UndanganModel undangan,
  ) async {
    final catatanCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
            SizedBox(width: 8),
            Text('Konfirmasi Hadir'),
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
            const SizedBox(height: 14),
            const Text('Catatan kehadiran (opsional):',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: catatanCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Tambahkan catatan...',
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Konfirmasi Hadir'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.success),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await up.updateStatus(
        id: undangan.id,
        newStatus: StatusUndangan.hadir,
        catatan: catatanCtrl.text.trim().isEmpty
            ? null
            : catatanCtrl.text.trim(),
      );
      if (ok && context.mounted) {
        AppUtils.showSuccess(
            context, up.lastMessage ?? 'Status berhasil diperbarui.');
        up.clearMessage();
      }
    }

    catatanCtrl.dispose();
  }

  Future<void> _showTidakHadirDialog(
    BuildContext context,
    UndanganProvider up,
    UndanganModel undangan,
  ) async {
    final catatanCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded,
                color: AppColors.danger, size: 22),
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
            const SizedBox(height: 14),
            const Text('Alasan tidak hadir (opsional):',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: catatanCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Masukkan alasan...',
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Konfirmasi'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await up.updateStatus(
        id: undangan.id,
        newStatus: StatusUndangan.tidakHadir,
        catatan: catatanCtrl.text.trim().isEmpty
            ? null
            : catatanCtrl.text.trim(),
      );
      if (ok && context.mounted) {
        AppUtils.showInfo(
            context, up.lastMessage ?? 'Status berhasil diperbarui.');
        up.clearMessage();
      }
    }

    catatanCtrl.dispose();
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    // final isTerlaksana = undangan.status == StatusUndangan.hadir;
    // final isTidakHadir = undangan.status == StatusUndangan.tidakHadir;
    final isPast = undangan.tanggal.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: title + badge ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    undangan.judul,
                    style: const TextStyle(
                      fontSize: 13,
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

          // ── Meta info ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaRow(
                  icon: Icons.business_rounded,
                  text: undangan.penyelenggara,
                ),
                const SizedBox(height: 4),
                _MetaRow(
                  icon: Icons.calendar_today_rounded,
                  text:
                      '${AppUtils.formatDate(undangan.tanggal)} · ${undangan.jam} WIB',
                  highlight: isPast && undangan.status == StatusUndangan.pending,
                ),
                const SizedBox(height: 4),
                _MetaRow(
                  icon: Icons.location_on_outlined,
                  text: undangan.lokasi,
                ),
                if (undangan.kegiatanTerkait != null) ...[
                  const SizedBox(height: 4),
                  _MetaRow(
                    icon: Icons.task_alt_rounded,
                    text: undangan.kegiatanTerkait!,
                    color: AppColors.primary,
                  ),
                ],
                if (undangan.catatan != null &&
                    undangan.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGray,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            undangan.catatan!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Action area ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 13),
            child: _ActionArea(
              status: undangan.status,
              isUpdating: isUpdating,
              onHadiri: onHadiri,
              onTidakHadir: onTidakHadir,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final bool highlight;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = highlight
        ? AppColors.danger
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
  final VoidCallback onHadiri;
  final VoidCallback onTidakHadir;

  const _ActionArea({
    required this.status,
    required this.isUpdating,
    required this.onHadiri,
    required this.onTidakHadir,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case StatusUndangan.hadir:
        return const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 15, color: AppColors.success),
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
            Icon(Icons.cancel_rounded,
                size: 15, color: AppColors.danger),
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
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isUpdating ? null : onHadiri,
                icon: const Icon(Icons.check_rounded, size: 15),
                label: const Text('Hadir',
                    style: TextStyle(fontSize: 12)),
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
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
          Text(
            _message,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
