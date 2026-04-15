import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/models/azkar_category.dart';

class AzkarCategoryCard extends StatelessWidget {
  final AzkarCategory category;
  final VoidCallback onTap;

  const AzkarCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  (IconData, Color) _getIconAndColor() {
    final id = category.id.toLowerCase();
    if (id.contains('morning') || id.contains('صباح')) {
      return (Icons.wb_sunny_outlined, const Color(0xFFF57F17));
    }
    if (id.contains('evening') || id.contains('مساء')) {
      return (Icons.nights_stay_outlined, const Color(0xFF283593));
    }
    if (id.contains('sleep') || id.contains('نوم')) {
      return (Icons.bedtime_outlined, const Color(0xFF4527A0));
    }
    if (id.contains('waking') || id.contains('استيقاظ')) {
      return (Icons.alarm_outlined, const Color(0xFFEF6C00));
    }
    if (id.contains('prayer') || id.contains('صلاة')) {
      return (Icons.mosque_outlined, const Color(0xFF2E7D32));
    }
    if (id.contains('mosque') || id.contains('مسجد')) {
      return (Icons.mosque, const Color(0xFF00695C));
    }
    if (id.contains('home') || id.contains('منزل')) {
      return (Icons.home_outlined, const Color(0xFF5D4037));
    }
    if (id.contains('food') || id.contains('طعام')) {
      return (Icons.restaurant_outlined, const Color(0xFFD84315));
    }
    if (id.contains('travel') || id.contains('سفر')) {
      return (Icons.flight_outlined, const Color(0xFF0277BD));
    }
    if (id.contains('clothes') || id.contains('لبس')) {
      return (Icons.checkroom_outlined, const Color(0xFF6A1B9A));
    }
    if (id.contains('bathroom') || id.contains('خلاء')) {
      return (Icons.water_drop_outlined, const Color(0xFF00838F));
    }
    if (id.contains('adhan') || id.contains('أذان')) {
      return (Icons.volume_up_outlined, const Color(0xFF1565C0));
    }
    if (id.contains('istikharah') || id.contains('استخارة')) {
      return (Icons.star_outline, const Color(0xFFAD1457));
    }
    if (id.contains('anxiety') || id.contains('كرب') || id.contains('هم')) {
      return (Icons.healing_outlined, const Color(0xFF00897B));
    }
    if (id.contains('ruqyah') || id.contains('رقية')) {
      return (Icons.shield_outlined, const Color(0xFF4E342E));
    }
    if (id.contains('general') || id.contains('عامة')) {
      return (Icons.auto_awesome_outlined, const Color(0xFF37474F));
    }
    return (Icons.auto_stories_outlined, AppColors.primary);
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getIconAndColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      elevation: 0,
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.nameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_toArabicNumber(category.azkarList.length)} ذكر',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new,
                size: 14,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
