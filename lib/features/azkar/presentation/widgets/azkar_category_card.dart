import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../domain/models/azkar_category.dart';

/// Minimal category row — white surface, hairline border, soft icon tint.
/// Alternates between green (primarySoft/primary) and gold
/// (secondarySoft/secondary) tints based on `index` to match the
/// Claude Design prototype's variety.
class AzkarCategoryCard extends StatelessWidget {
  final AzkarCategory category;
  final int index;
  final VoidCallback onTap;

  const AzkarCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.index = 0,
  });

  (IconData, String) _iconAndSubtitle() {
    final id = category.id.toLowerCase();
    if (id.contains('morning') || category.nameAr.contains('الصباح')) {
      return (Icons.wb_sunny_outlined, 'بعد صلاة الفجر');
    }
    if (id.contains('evening') || category.nameAr.contains('المساء')) {
      return (Icons.nights_stay_outlined, 'بعد صلاة العصر');
    }
    if (id.contains('sleep') || category.nameAr.contains('النوم')) {
      return (Icons.bedtime_outlined, 'قبل النوم');
    }
    if (id.contains('waking') || category.nameAr.contains('الاستيقاظ')) {
      return (Icons.brightness_4_outlined, 'عند الاستيقاظ');
    }
    if (id.contains('prayer') || category.nameAr.contains('الصلاة')) {
      return (Icons.mosque_outlined, 'بعد كل فريضة');
    }
    if (id.contains('mosque') || category.nameAr.contains('المسجد')) {
      return (Icons.place_outlined, 'عند دخول المسجد');
    }
    if (id.contains('home') || category.nameAr.contains('المنزل')) {
      return (Icons.home_outlined, 'عند دخول البيت');
    }
    if (id.contains('food') || category.nameAr.contains('الطعام')) {
      return (Icons.restaurant_outlined, 'عند الأكل والشرب');
    }
    if (id.contains('travel') || category.nameAr.contains('السفر')) {
      return (Icons.flight_outlined, 'عند السفر');
    }
    if (id.contains('clothes') || category.nameAr.contains('اللباس')) {
      return (Icons.checkroom_outlined, 'عند لبس الثوب');
    }
    if (id.contains('bathroom') || category.nameAr.contains('الخلاء')) {
      return (Icons.water_drop_outlined, 'عند دخول وخروج الخلاء');
    }
    if (id.contains('adhan') || category.nameAr.contains('الأذان')) {
      return (Icons.volume_up_outlined, 'عند سماع الأذان');
    }
    if (id.contains('istikharah') || category.nameAr.contains('الاستخارة')) {
      return (Icons.star_outline, 'دعاء الاستخارة');
    }
    if (category.nameAr.contains('كرب') || category.nameAr.contains('هم')) {
      return (Icons.healing_outlined, 'عند الكرب والهم');
    }
    if (id.contains('ruqyah') || category.nameAr.contains('الرقية')) {
      return (Icons.shield_outlined, 'رقية شرعية');
    }
    return (Icons.auto_stories_outlined, 'مجموعة أذكار مختارة');
  }

  @override
  Widget build(BuildContext context) {
    final (icon, subtitle) = _iconAndSubtitle();
    final isGold = index.isEven;
    final tint = isGold ? AppColors.secondarySoft : AppColors.primarySoft;
    final iconColor = isGold ? AppColors.secondary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 4,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.md + 2,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.md + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.nameAr,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSunk,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    ArabicNumberUtils.toEasternArabic(category.azkarList.length),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.ink3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_left_rounded,
                  size: 18,
                  color: AppColors.ink3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
