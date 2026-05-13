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

    final route =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    // ✅ Admin checker
    final isAdmin = user?.role == 'Admin';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            _DrawerHeader(
              name: user?.username ?? 'Pengguna',
              jabatan: user?.roleLabel ?? '-',
              initials: user?.initials ?? 'U',
              isAdmin: isAdmin,
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

                  // ── ADMIN SECTION ────────────────────────────────────────
                  if (isAdmin) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                                width: 0.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 10,
                                  color: AppColors.warning,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Container(
                              height: 0.5,
                              color: AppColors.border,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _DrawerItem(
                      icon: Icons.manage_search_rounded,
                      label: 'Kelola Kegiatan',
                      route: AppRoutes.adminKegiatan,
                      currentRoute: route,
                      accentColor: AppColors.warning,
                    ),

                    _DrawerItem(
                      icon: Icons.mark_email_unread_rounded,
                      label: 'Kelola Undangan',
                      route: AppRoutes.adminUndangan,
                      currentRoute: route,
                      accentColor: AppColors.warning,
                    ),
                  ],
                ],
              ),
            ),

            // ── Bottom ──────────────────────────────────────────────────────
            const Divider(),

            _DrawerItem(
              icon: Icons.info_outline_rounded,
              label: AppStrings.tentang,
              route: AppRoutes.tentang,
              currentRoute: route,
            ),

            _LogoutButton(
              onLogout: () => _doLogout(context, auth),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _doLogout(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    final confirm = await showDialog<bool>(
      context: navigator.context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi SIPEKA?',
        ),
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

    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );

    try {
      await auth.logout();

      navigator.pop();

      navigator.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
    } catch (e) {
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal logout, coba lagi'),
        ),
      );
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String jabatan;
  final String initials;
  final bool isAdmin;

  const _DrawerHeader({
    required this.name,
    required this.jabatan,
    required this.initials,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Image(
                  image: AssetImage(
                    'assets/images/dinsos_logo.png',
                  ),
                  width: 22,
                  height: 22,
                ),
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
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // User Info
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAdmin
                        ? const Color(0xFFFEF3C7)
                        : AppColors.primaryLight,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isAdmin
                            ? AppColors.warning
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),

                  if (isAdmin)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
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
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
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

// ─── Drawer Item ──────────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final int? badge;
  final Color? accentColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.badge,
    this.accentColor,
  });

  bool get _active => currentRoute == route;

  Color get _accent => accentColor ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: _active
            ? (_accent == AppColors.warning
                ? const Color(0xFFFFFBEB)
                : AppColors.primaryLight)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: Icon(
          icon,
          size: 20,
          color: _active ? _accent : AppColors.textMuted,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                _active ? FontWeight.w500 : FontWeight.w400,
            color:
                _active ? _accent : AppColors.textSecondary,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : _active
                ? Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                : null,
        onTap: () {
          Navigator.pop(context);

          if (!_active) {
            Navigator.pushReplacementNamed(
              context,
              route,
            );
          }
        },
      ),
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: const Icon(
          Icons.logout_rounded,
          size: 20,
          color: AppColors.danger,
        ),
        title: const Text(
          AppStrings.logout,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.danger,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onLogout,
      ),
    );
  }
}