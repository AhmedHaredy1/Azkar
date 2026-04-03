import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class DhikrCard extends StatelessWidget {
  final String text;
  final String source;
  final String note;

  const DhikrCard({
    super.key,
    required this.text,
    this.source = '',
    this.note = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Decorative top border
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.0),
                  AppColors.secondary.withValues(alpha: 0.5),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),
          // Islamic corner ornaments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '﴾',
                  style: GoogleFonts.amiri(
                    fontSize: 28,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  '﴿',
                  style: GoogleFonts.amiri(
                    fontSize: 28,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          // Dhikr text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 23,
                height: 2.0,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Source badge
          if (source.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                source,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                note,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Decorative bottom border
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.0),
                  AppColors.secondary.withValues(alpha: 0.5),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
