// lib/widgets/summary_card.dart

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final double? size;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final Color? bgColor;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.size,
    this.subtitle,
    required this.icon,
    this.accentColor,
    this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;
    final bg = bgColor ?? AppColors.primaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withOpacity(0.25),
            width: 0.75,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: accent.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: size ?? 18,
                fontWeight: FontWeight.w700,
                color: accent,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 10,
                  color: accent.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
