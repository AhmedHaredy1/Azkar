import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/dua_category.dart';

class DuaTextCard extends StatelessWidget {
  final Dua dua;
  final int index;

  const DuaTextCard({
    super.key,
    required this.dua,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dua text
          Text(
            dua.textAr,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 20,
              height: 2.0,
              color: AppColors.textPrimary,
            ),
          ),
          if (dua.source.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              dua.source,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Share button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                final shareText =
                    '${dua.textAr}\n\n${dua.source.isNotEmpty ? "المصدر: ${dua.source}" : ""}\n\nمن تطبيق حصن المسلم';
                Share.share(shareText);
              },
              icon: const Icon(
                Icons.share_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              tooltip: 'مشاركة',
            ),
          ),
        ],
      ),
    );
  }
}
