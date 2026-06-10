import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../../core/theme/tokens.dart';

/// Color-swatch picker used in Settings → Appearance.
///
/// Replaces the old light/dark/system mode toggle. The app is now light-only;
/// what the user picks here is the *accent palette* (primary + secondary tones)
/// that propagates through the whole app via [ActivePalette]/[AppColors].
class ThemeSelector extends StatelessWidget {
  final String currentId;
  final ValueChanged<String> onChanged;

  const ThemeSelector({
    super.key,
    required this.currentId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لون التطبيق',
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (int i = 0; i < AppPalettes.all.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PaletteSwatch(
                  palette: AppPalettes.all[i],
                  isSelected: AppPalettes.all[i].id == currentId,
                  onTap: () => onChanged(AppPalettes.all[i].id),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  final ThemePalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaletteSwatch({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? palette.primary : AppColors.hairline,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.primary, palette.secondary],
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              palette.nameAr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? palette.primary : AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
