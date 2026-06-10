import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// 8-point geometric star — the single ornament used across the app.
/// Restrained, used sparingly on heroes and section markers.
class StarMark extends StatelessWidget {
  final double size;
  final Color? color;
  final double opacity;

  const StarMark({
    super.key,
    this.size = 14,
    this.color,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(size, size),
        painter: _StarPainter(color: color ?? AppColors.primary, filled: true),
      ),
    );
  }
}

/// Outlined 8-point star.
class StarOutline extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const StarOutline({
    super.key,
    this.size = 18,
    this.color,
    this.strokeWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StarPainter(
        color: color ?? AppColors.primary,
        filled: false,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  final bool filled;
  final double strokeWidth;

  _StarPainter({required this.color, required this.filled, this.strokeWidth = 1});

  @override
  void paint(Canvas canvas, Size size) {
    // 8-point star path on a 24x24 viewbox.
    final scale = size.width / 24.0;
    final path = Path()
      ..moveTo(12 * scale, 1 * scale)
      ..lineTo(14.6 * scale, 9.4 * scale)
      ..lineTo(23 * scale, 12 * scale)
      ..lineTo(14.6 * scale, 14.6 * scale)
      ..lineTo(12 * scale, 23 * scale)
      ..lineTo(9.4 * scale, 14.6 * scale)
      ..lineTo(1 * scale, 12 * scale)
      ..lineTo(9.4 * scale, 9.4 * scale)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.filled != filled || old.strokeWidth != strokeWidth;
}

/// Faint geometric watermark — concentric circles + overlapping 8-point stars.
/// Positioned absolutely; use inside a Stack on hero cards.
class GeoWatermark extends StatelessWidget {
  final double opacity;
  final Color? color;
  final double size;

  const GeoWatermark({
    super.key,
    this.opacity = 0.05,
    this.color,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          size: Size(size, size),
          painter: _GeoWatermarkPainter(color: color ?? AppColors.primary),
        ),
      ),
    );
  }
}

class _GeoWatermarkPainter extends CustomPainter {
  final Color color;

  _GeoWatermarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * scale;

    final center = Offset(50 * scale, 50 * scale);
    canvas.drawCircle(center, 40 * scale, paint);
    canvas.drawCircle(center, 30 * scale, paint);

    // Outer 8-point star (vertices 40 out from center)
    canvas.drawPath(_star(scale, 40, 30), paint);
    // Inner 8-point star (vertices 30 out from center)
    canvas.drawPath(_star(scale, 30, 25), paint);
  }

  Path _star(double scale, double outer, double inner) {
    // 8-point star roughly matching the original SVG.
    final p = Path()
      ..moveTo(50 * scale, (50 - outer) * scale)
      ..lineTo((50 + inner * 0.25) * scale, (50 - inner * 0.25) * scale)
      ..lineTo((50 + outer) * scale, 50 * scale)
      ..lineTo((50 + inner * 0.25) * scale, (50 + inner * 0.25) * scale)
      ..lineTo(50 * scale, (50 + outer) * scale)
      ..lineTo((50 - inner * 0.25) * scale, (50 + inner * 0.25) * scale)
      ..lineTo((50 - outer) * scale, 50 * scale)
      ..lineTo((50 - inner * 0.25) * scale, (50 - inner * 0.25) * scale)
      ..close();
    return p;
  }

  @override
  bool shouldRepaint(_GeoWatermarkPainter old) => old.color != color;
}

/// Thin hair divider — uses the hairline token.
class HairDivider extends StatelessWidget {
  final double? indent;
  final Color? color;

  const HairDivider({super.key, this.indent, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsetsDirectional.only(
        start: indent ?? 0,
        end: indent ?? 0,
      ),
      color: color ?? AppColors.hairline,
    );
  }
}
