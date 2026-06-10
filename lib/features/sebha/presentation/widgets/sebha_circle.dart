import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_utils.dart';

/// Tasbeeh counter — matches the Claude Design prototype's `TasbeehScreen`.
/// Outer ring with a primary-tinted progress arc, 33 tick marks around the
/// circumference, large centered counter, "/ target" label, and a "مكتمل"
/// pill when progress hits 100%.
class SebhaCircle extends StatefulWidget {
  final int currentCount;
  final int targetCount;
  final VoidCallback onTap;

  const SebhaCircle({
    super.key,
    required this.currentCount,
    required this.targetCount,
    required this.onTap,
  });

  @override
  State<SebhaCircle> createState() => _SebhaCircleState();
}

class _SebhaCircleState extends State<SebhaCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.targetCount > 0
        ? (widget.currentCount / widget.targetCount).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = progress >= 1.0;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: _SebhaArcPainter(
              progress: progress,
              ticks: widget.targetCount <= 100 ? widget.targetCount : 0,
              filledTicks: widget.currentCount.clamp(0, widget.targetCount),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ArabicNumberUtils.toEasternArabic(widget.currentCount),
                    style: GoogleFonts.cairo(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: AppColors.ink,
                      height: 1,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '/ ${ArabicNumberUtils.toEasternArabic(widget.targetCount)}',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'مكتمل',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SebhaArcPainter extends CustomPainter {
  final double progress;
  final int ticks;
  final int filledTicks;

  _SebhaArcPainter({
    required this.progress,
    required this.ticks,
    required this.filledTicks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final track = Paint()
      ..color = AppColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final arc = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        arc,
      );
    }

    if (ticks > 0) {
      final tickOn = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final tickOff = Paint()
        ..color = AppColors.hairlineStrong
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final rInner = radius - 12;
      final rOuter = radius - 6;
      for (int i = 0; i < ticks; i++) {
        final a = (i / ticks) * 2 * math.pi - math.pi / 2;
        final p1 = center + Offset(math.cos(a) * rInner, math.sin(a) * rInner);
        final p2 = center + Offset(math.cos(a) * rOuter, math.sin(a) * rOuter);
        canvas.drawLine(p1, p2, i < filledTicks ? tickOn : tickOff);
      }
    }
  }

  @override
  bool shouldRepaint(_SebhaArcPainter old) =>
      old.progress != progress ||
      old.ticks != ticks ||
      old.filledTicks != filledTicks;
}
