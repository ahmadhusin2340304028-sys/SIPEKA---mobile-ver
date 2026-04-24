// lib/screens/kegiatan/kegiatan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/kegiatan_provider.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/kegiatan_card.dart';

class KegiatanScreen extends StatefulWidget {
  const KegiatanScreen({super.key});

  @override
  State<KegiatanScreen> createState() => _KegiatanScreenState();
}

class _KegiatanScreenState extends State<KegiatanScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ Hapus guard !kp.isLoaded — selalu load ulang saat screen dibuka
      context.read<KegiatanProvider>().loadKegiatan();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kp = context.watch<KegiatanProvider>();
    final list = kp.filteredKegiatan;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.kegiatan)),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // ── Search + Filters ─────────────────────────────────────────────
          _SearchFilterBar(
            controller: _searchCtrl,
            bidangOptions: ['Semua', ...kp.allBidang],
            selectedBidang: kp.selectedBidang,
            onSearch: (q) => kp.setSearch(q),
            onBidangSelect: (b) =>
                kp.setBidangFilter(b == 'Semua' ? null : b),
            onClear: () {
              _searchCtrl.clear();
              kp.clearFilters();
            },
          ),
          const Divider(height: 0),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: kp.isLoading
                ? const Center(child: CircularProgressIndicator())
                : kp.loadState == LoadState.error
                    // ✅ Tampilkan error state agar user tahu masalahnya
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              kp.errorMessage ?? 'Gagal memuat data',
                              style: const TextStyle(color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: kp.loadKegiatan,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : list.isEmpty
                        ? _EmptyState(
                            hasFilter: kp.searchQuery.isNotEmpty ||
                                kp.selectedBidang != null,
                            onClear: () {
                              _searchCtrl.clear();
                              kp.clearFilters();
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: kp.loadKegiatan,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final k = list[i];
                                return KegiatanCard(
                                  kegiatan: k,
                                  onTap: () {
                                    kp.selectKegiatan(k);
                                    Navigator.pushNamed(
                                        context, AppRoutes.detailKegiatan);
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Search + Filter Bar ──────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final List<String> bidangOptions;
  final String? selectedBidang;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onBidangSelect;
  final VoidCallback onClear;

  const _SearchFilterBar({
    required this.controller,
    required this.bidangOptions,
    required this.selectedBidang,
    required this.onSearch,
    required this.onBidangSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Cari kegiatan, bidang, pelaksana...',
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 20, color: AppColors.textMuted),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 18, color: AppColors.textMuted),
                      onPressed: onClear,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),

          // Bidang chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bidangOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (ctx, i) {
                final opt = bidangOptions[i];
                final isSelected = opt == 'Semua'
                    ? selectedBidang == null
                    : selectedBidang == opt;
                return _FilterChip(
                  label: opt,
                  isSelected: isSelected,
                  onTap: () => onBidangSelect(opt),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary : AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 0 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color:
                isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter
                ? Icons.search_off_rounded
                : Icons.folder_open_rounded,
            size: 56,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 14),
          Text(
            hasFilter
                ? 'Tidak ada kegiatan yang cocok'
                : 'Belum ada data kegiatan',
            style: const TextStyle(
                fontSize: 14, color: AppColors.textMuted),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClear,
              child: const Text('Hapus filter'),
            ),
          ],
        ],
      ),
    );
  }
}
