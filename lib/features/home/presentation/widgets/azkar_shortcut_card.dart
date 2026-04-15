import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../providers/home_provider.dart';

class AzkarShortcutCard extends ConsumerWidget {
  const AzkarShortcutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMorning = ref.watch(isMorningProvider);

    // Show morning azkar button before Dhuhr, evening azkar button after
    final String label;
    final String subtitle;
    final IconData icon;
    final String categoryId;
    final Color accentColor;

    if (isMorning) {
      label = 'أذكار الصباح';
      subtitle = 'ابدأ يومك بذكر الله';
      icon = Icons.wb_sunny_outlined;
      categoryId = 'morning';
      accentColor = const Color(0xFFF57F17); // warm amber
    } else {
      label = 'أذكار المساء';
      subtitle = 'لا تنسَ أذكار المساء';
      icon = Icons.nights_stay_outlined;
      categoryId = 'evening';
      accentColor = const Color(0xFF5C6BC0); // indigo
    }

    return GestureDetector(
      onTap: () => context.push('/azkar/$categoryId'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              accentColor.withValues(alpha: 0.12),
              accentColor.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 26,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: accentColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
