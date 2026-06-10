import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class FontSizeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const FontSizeSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A45) : AppColors.background;
    final borderColor = isDark ? const Color(0xFF3A3A55) : const Color(0xFFE8E4DB);
    final textColor = isDark ? const Color(0xFFE8E6E3) : const Color(0xFF1A1A1A);
    final secondaryText = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5A5A5A);
    final primaryColor = isDark ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: value,
              height: 1.8,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Slider
        Row(
          children: [
            Text(
              'أ',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: secondaryText,
              ),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: 16,
                max: 36,
                divisions: 20,
                activeColor: primaryColor,
                inactiveColor: primaryColor.withValues(alpha: 0.2),
                label: value.toInt().toString(),
                onChanged: onChanged,
              ),
            ),
            Text(
              'أ',
              style: GoogleFonts.cairo(
                fontSize: 24,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
