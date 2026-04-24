// lib/widgets/custom_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/undangan_provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final undangan = context.watch<UndanganProvider>();
    final user = auth.user;
    final route = ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            // ✅ SESUDAH — pakai roleLabel yang sudah handle null
            _DrawerHeader(
              name: user?.username ?? 'Pengguna',
              jabatan: user?.roleLabel ?? '-',   // ← ganti ke roleLabel
              initials: user?.initials ?? 'U',
            ),

            // ── Nav Items ─────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: AppStrings.dashboard,
                    route: AppRoutes.dashboard,
                    currentRoute: route,
                  ),
                  _DrawerItem(
                    icon: Icons.task_alt_rounded,
                    label: AppStrings.kegiatan,
                    route: AppRoutes.kegiatan,
                    currentRoute: route,
                  ),
                  _DrawerItem(
                    icon: Icons.mail_outline_rounded,
                    label: AppStrings.undangan,
                    route: AppRoutes.undangan,
                    currentRoute: route,
                    badge: undangan.pendingCount > 0
                        ? undangan.pendingCount
                        : null,
                  ),                                   
                ],
              ),
            ),

            // ── Logout ────────────────────────────────────────────────────────
            const Divider(),
            _LogoutButton(onLogout: () => _doLogout(context, auth)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _doLogout(BuildContext context, AuthProvider auth) async {
  // ✅ Simpan navigator SEBELUM pop — context masih valid di sini
  final navigator = Navigator.of(context, rootNavigator: true);
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Tutup drawer
  Navigator.pop(context);

  // Tampilkan dialog konfirmasi menggunakan navigator yang sudah disimpan
  final confirm = await showDialog<bool>(
    context: navigator.context,  // ✅ pakai navigator.context bukan context drawer
    builder: (ctx) => AlertDialog(
      title: const Text('Konfirmasi Keluar'),
      content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi SIPEKA?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
          ),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  // Tampilkan loading
  showDialog(
    context: navigator.context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: Colors.white),
    ),
  );

  try {
    await auth.logout();

    // Tutup loading dialog
    navigator.pop();

    // ✅ Navigasi ke login, hapus semua route
    navigator.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  } catch (e) {
    navigator.pop(); // tutup loading

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Gagal logout, coba lagi')),
    );
  }
}
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String jabatan;
  final String initials;

  const _DrawerHeader({
    required this.name,
    required this.jabatan,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Kinerja & Anggaran',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      jabatan,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final int? badge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.badge,
  });

  bool get _active => currentRoute == route;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: _active ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          icon,
          size: 20,
          color: _active ? AppColors.primary : AppColors.textMuted,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                _active ? FontWeight.w500 : FontWeight.w400,
            color:
                _active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              )
            : _active
                ? Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                : null,
        onTap: () {
          Navigator.pop(context);
          if (!_active) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: const Icon(Icons.logout_rounded,
            size: 20, color: AppColors.danger),
        title: const Text(
          AppStrings.logout,
          style: TextStyle(
              fontSize: 13,
              color: AppColors.danger,
              fontWeight: FontWeight.w500),
        ),
        onTap: onLogout,
      ),
    );
  }
}
