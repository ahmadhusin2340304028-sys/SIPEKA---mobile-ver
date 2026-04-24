// lib/core/utils/app_utils.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class AppUtils {
  AppUtils._();

  // ─── Formatters ───────────────────────────────────────────────────────────

  static String formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String formatCurrencyCompact(num amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)} M';
    }
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(0)} Jt';
    }
    if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)} Rb';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  static String formatPercent(double value) =>
      '${value.toStringAsFixed(1)}%';

  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  static String formatDateFull(DateTime date) =>
      DateFormat('EEEE, dd MMMM yyyy').format(date);

  // ─── Progress color ───────────────────────────────────────────────────────

  static Color progressColor(double percent) {
    if (percent >= 80) return AppColors.success;
    if (percent >= 50) return AppColors.primary;
    return AppColors.warning;
  }

  static String progressLabel(double percent) {
    if (percent >= 80) return 'On Track';
    if (percent >= 50) return 'Perlu Perhatian';
    return 'At Risk';
  }

  // ─── Snackbar ─────────────────────────────────────────────────────────────

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check_circle_rounded);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.danger, Icons.error_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.primary, Icons.info_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
  }


  // ─── Initials ─────────────────────────────────────────────────────────────

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
