import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeSelector({
    super.key,
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A45) : const Color(0xFFFAF8F3);
    final borderColor = isDark ? const Color(0xFF3A3A55) : const Color(0xFFE8E4DB);
    final textColor = isDark ? const Color(0xFFE8E6E3) : const Color(0xFF1A1A1A);
    final secondaryText = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5A5A5A);
    final selectedColor = isDark ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20);

    return Row(
      children: [
        _ThemeOption(
          icon: Icons.light_mode_outlined,
          label: 'فاتح',
          isSelected: currentMode == ThemeMode.light,
          onTap: () => onChanged(ThemeMode.light),
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          secondaryText: secondaryText,
          selectedColor: selectedColor,
        ),
        const SizedBox(width: 10),
        _ThemeOption(
          icon: Icons.dark_mode_outlined,
          label: 'داكن',
          isSelected: currentMode == ThemeMode.dark,
          onTap: () => onChanged(ThemeMode.dark),
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          secondaryText: secondaryText,
          selectedColor: selectedColor,
        ),
        const SizedBox(width: 10),
        _ThemeOption(
          icon: Icons.settings_brightness_outlined,
          label: 'تلقائي',
          isSelected: currentMode == ThemeMode.system,
          onTap: () => onChanged(ThemeMode.system),
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          secondaryText: secondaryText,
          selectedColor: selectedColor,
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color secondaryText;
  final Color selectedColor;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.secondaryText,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withValues(alpha: 0.1) : cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedColor : borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? selectedColor : secondaryText,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? selectedColor : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
