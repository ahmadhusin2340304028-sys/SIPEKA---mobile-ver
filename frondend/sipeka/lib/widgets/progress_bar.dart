// lib/widgets/progress_bar.dart

// lib/widgets/progress_bar.dart

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_utils.dart';

class AppProgressBar extends StatefulWidget {
  final String label;
  final double value; 
  final double target;  // langsung 0–100 (persen), BUKAN raw value
  final Color? color;
  final bool animated;
  final bool showPercent;
  final double height;

  const AppProgressBar({
    super.key,
    required this.label,
    required this.value, // ← HAPUS parameter 'target'
    required this.target,
    this.color,
    this.animated = true,
    this.showPercent = true,
    this.height = 7,
  });

  @override
  State<AppProgressBar> createState() => _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // ✅ value sudah dalam persen (0–100), bagi 100 untuk LinearProgressIndicator
    _anim = Tween<double>(
      begin: 0,
      end: (widget.value / widget.target).clamp(0.0, 1.0), // ← simpan sebagai 0.0–1.0
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.animated) _ctrl.forward();
  }

  @override
  void didUpdateWidget(AppProgressBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(
        begin: _anim.value,
        end: (widget.value / widget.target).clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _barColor => widget.color ?? AppUtils.progressColor(widget.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.showPercent)
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => Text(
                    // ✅ _anim sudah 0.0–1.0, kali 100 untuk tampilan
                    '${(_anim.value * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _barColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.height / 2),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => LinearProgressIndicator(
                value: _anim.value, // ✅ sudah 0.0–1.0
                minHeight: widget.height,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─── Dual Progress (fisik + anggaran) ─────────────────────────────────────────

// class DualProgressBar extends StatelessWidget {
//   final double progressFisik;
//   final double progressAnggaran;
//   final double target;

//   const DualProgressBar({
//     super.key,
//     required this.progressFisik,
//     required this.progressAnggaran,
//     required this.target,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         AppProgressBar(label: 'Realisasi Fisik', target: target, value: progressFisik),
//         AppProgressBar(
//           label: 'Realisasi Anggaran',
//           target: target,
//           value: progressAnggaran,
//           color: AppColors.primaryMid,
//         ),
//       ],
//     );
//   }
// }
