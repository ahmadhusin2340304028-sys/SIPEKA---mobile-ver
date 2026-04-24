// lib/screens/dashboard/dashboard_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kegiatan_provider.dart';
import '../../providers/undangan_provider.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/progress_bar.dart';
import '../../models/kegiatan_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kp = context.read<KegiatanProvider>();
      final up = context.read<UndanganProvider>();
      // ✅ INI YANG KURANG
      kp.loadDashboard();

      if (up.allUndangan.isEmpty) up.loadUndangan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final kp = context.watch<KegiatanProvider>();
    final up = context.watch<UndanganProvider>();
    final user = auth.user;
    final summary = kp.summary;

    // dashboard_screen.dart — di dalam build()

    // Jika loading selesai tapi summary masih null, tampilkan pesan
    if (!kp.isLoading && kp.summary == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('Gagal memuat data dashboard',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => kp.loadDashboard(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white.withOpacity(0.22),
              child: Text(
                user?.initials ?? 'U',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: kp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await kp.loadDashboard();
                await up.loadUndangan();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Greeting ───────────────────────────────────────────────
                  _GreetingBanner(name: user?.username ?? 'User'),
                  const SizedBox(height: 18),

                  // ── Summary Cards ──────────────────────────────────────────
                  const _SectionTitle('Ringkasan Kinerja'),
                  const SizedBox(height: 10),
                  if (summary != null) ...[
                    // Row 1
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            label: 'Total Kegiatan',
                            value: '${summary.totalKegiatan}',
                            size: 22,
                            subtitle: 'Tahun ${DateTime.now().year}',
                            icon: Icons.task_alt_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SummaryCard(
                            label: 'Realisasi Fisik',
                            value: summary.rataRataFisik.toStringAsFixed(1),
                            size: 22,
                            subtitle: 'Rata-rata',
                            icon: Icons.trending_up_rounded,
                            accentColor: AppUtils.progressColor(
                                summary.rataRataFisik),
                            bgColor: AppUtils.progressColor(
                                    summary.rataRataFisik)
                                .withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row 2
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            label: 'Total Anggaran',
                            value: AppUtils.formatCurrency(summary.totalAnggaran),
                            size: 18,
                            subtitle: 'kegiatan',
                            icon: Icons.money_rounded,
                            accentColor: AppColors.success,
                            bgColor: AppColors.successLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SummaryCard(
                            label: 'Target Fisik',
                            value: '${(summary.totalRealisasiFisik / summary.totalTarget * 100).toStringAsFixed(1)}%',
                            size: 22,
                            subtitle: 'Terealisasi',
                            icon: Icons.analytics_rounded,
                            accentColor: AppColors.warning,
                            bgColor: AppColors.warningLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Anggaran full-width
                    _AnggaranCard(summary: summary),
                  ],

                  const SizedBox(height: 20),

                  // ── Progress per Bidang ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle('Progres per Bidang'),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.kegiatan),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Lihat semua',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _BidangProgressCard(summary: summary!),

                  const SizedBox(height: 20),

                  // ── Quick Actions ──────────────────────────────────────────
                  const _SectionTitle('Aksi Cepat'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded( 
                        child: _QuickAction(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Input Realisasi',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.kegiatan),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.mail_outline_rounded,
                          label: 'Undangan',
                          badge: up.pendingCount,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.undangan),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
}

class _GreetingBanner extends StatelessWidget {
  final String name;
  const _GreetingBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFBFDBFE), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.waving_hand_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Haloo '),
                  TextSpan(
                    text: name.split(' ').first,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const TextSpan(
                      text: ' — Selamat datang di SIPEKA'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnggaranCard extends StatelessWidget {
  final DashboardSummary summary;
  const _AnggaranCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = summary.totalAnggaran > 0
        ? (summary.totalRealisasi / summary.totalAnggaran * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFBFDBFE), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Total Anggaran Terrealisasi',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryMid,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppUtils.formatCurrencyCompact(summary.totalRealisasi),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            'dari ${AppUtils.formatCurrency(summary.totalAnggaran)}',
            style: const TextStyle(
                fontSize: 11, color: AppColors.primaryMid),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFBFDBFE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pct.toStringAsFixed(1)}% terrealisasi',
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _BidangProgressCard extends StatelessWidget {
  final DashboardSummary summary;

  const _BidangProgressCard({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.bidangProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: summary.bidangProgress.map((b) {
          return AppProgressBar(
            label: b.nama,
            value: b.totalRealisasiFisik,
            target: b.totalTarget,
          );
        }).toList(),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: AppColors.danger, shape: BoxShape.circle),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
