// lib/screens/kegiatan/detail_kegiatan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipeka/models/kegiatan_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/kegiatan_provider.dart';
import '../../widgets/progress_bar.dart';

class DetailKegiatanScreen extends StatefulWidget {
  const DetailKegiatanScreen({super.key});

  @override
  State<DetailKegiatanScreen> createState() => _DetailKegiatanScreenState();
}

class _DetailKegiatanScreenState extends State<DetailKegiatanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kp = context.read<KegiatanProvider>();
      if (kp.selected != null) {
        // ✅ Fetch detail lengkap termasuk realisasi_fisik per bulan
        kp.loadKegiatanDetail(kp.selected!.id);
        
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final kegiatan = context.watch<KegiatanProvider>().selected;
    print("kegiatan: $kegiatan. Detail: ${kegiatan != null ? kegiatan.realisasiBulanan : 'null'}");
    if (kegiatan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.detailKegiatan)),
        body: const Center(
          child: Text('Data tidak tersedia.',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.detailKegiatan)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ─────────────────────────────────────────────────
            _HeaderCard(kegiatan: kegiatan),
            const SizedBox(height: 12),

            // ── Info Table ───────────────────────────────────────────────────
            _InfoCard(
              title: 'Informasi Kegiatan',
              rows: [
                _InfoRow('Sasaran Strategis', kegiatan.sasaranStrategis),
                _InfoRow('Indikator', kegiatan.indikatorKinerja),
                _InfoRow('Program', kegiatan.program),
                _InfoRow('Kegiatan', kegiatan.kegiatan),
                _InfoRow('Sub Kegiatan', kegiatan.subKegiatan),
                _InfoRow('Target Fisik', '${kegiatan.target.toStringAsFixed(0)} ${kegiatan.satuan}'),
                _InfoRow('Realisasi Fisik', '${kegiatan.totalRealisasiFisik.toStringAsFixed(0)} ${kegiatan.satuan}'),
                _InfoRow('Sisa Target', '${kegiatan.sisaTarget.toStringAsFixed(0)} ${kegiatan.satuan}'),
                _InfoRow('Pagu Anggaran',
                    AppUtils.formatCurrency(kegiatan.paguAnggaran)),
                _InfoRow('Realisasi Anggaran',
                    AppUtils.formatCurrency(kegiatan.totalRealisasiAnggaran)),
                _InfoRow('Sisa Anggaran',
                    AppUtils.formatCurrency(kegiatan.sisaAnggaran)),
                _InfoRow('Pelaksana', kegiatan.bidang),
                _InfoRow('Tahun Anggaran', kegiatan.tahun.toString()),
              ],
            ),
            const SizedBox(height: 12),

            // ── Progress Card ────────────────────────────────────────────────
            _Card(
              title: 'Capaian Realisasi',
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  AppProgressBar(
                    label: 'Realisasi Fisik',
                    target: kegiatan.target,
                    value: kegiatan.progressFisik,
                  ),
                  AppProgressBar(
                    label: 'Realisasi Anggaran',
                    target: kegiatan.target,
                    value: kegiatan.progressAnggaran,
                    color: AppColors.primaryMid,
                  ),
                  // Status pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _StatusPill(status: AppUtils.progressLabel(
                          kegiatan.progressFisik)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Monthly Chart ─────────────────────────────────────────────────
            if ((kegiatan.realisasiBulanan).isNotEmpty) ...[
              _Card(
                title: 'Realisasi Fisik per Bulan (%)',
                child: _MonthlyBarChart(
                    data: kegiatan.realisasiBulanan),
              ),
              const SizedBox(height: 12),
            ],

            // ── CTA ───────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.inputRealisasi),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Input Realisasi',
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

// ─── Header Card ─────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final KegiatanModel kegiatan;
  const _HeaderCard({required this.kegiatan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kegiatan.nama,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: [
              _Chip(
                  label: kegiatan.bidang,
                  bg: AppColors.primaryLight,
                  fg: AppColors.primaryDark),
              _Chip(
                  label: kegiatan.tahun.toString(),
                  bg: AppColors.surfaceGray,
                  fg: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

// ─── Generic Card wrapper ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Info Table Card ──────────────────────────────────────────────────────────

class _InfoRow {
  final String key;
  final String value;
  _InfoRow(this.key, this.value);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 0),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                            color: AppColors.border, width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(e.value.key,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ),
                  Expanded(
                    child: Text(
                      e.value.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Monthly Bar Chart ────────────────────────────────────────────────────────

class _MonthlyBarChart extends StatefulWidget {
  final List data;
  const _MonthlyBarChart({required this.data});

  @override
  State<_MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<_MonthlyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                   'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.data.fold<double>(
        1, (prev, e) => e.fisik > prev ? e.fisik.toDouble() : prev);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        height: 90,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: widget.data.map<Widget>((d) {
            final frac = (d.fisik / maxVal) * _anim.value;
            final monthLabel = d.bulan >= 1 && d.bulan <= 12
                ? _months[d.bulan - 1]
                : '?';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${d.fisik.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 7.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                      child: Container(
                        height: 55 * frac.clamp(0.05, 1.0) as double,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthLabel,
                      style: const TextStyle(
                          fontSize: 8, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    IconData icon;
    switch (status) {
      case 'On Track':
        bg = AppColors.successLight;
        fg = const Color(0xFF166534);
        icon = Icons.check_circle_rounded;
        break;
      case 'Selesai':
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
        icon = Icons.verified_rounded;
        break;
      default:
        bg = AppColors.warningLight;
        fg = const Color(0xFF92400E);
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(status,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
