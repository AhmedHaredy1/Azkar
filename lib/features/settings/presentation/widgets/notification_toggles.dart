import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/settings_provider.dart';

/// Displays a grouped list of notification toggles for prayers and Azkar reminders.
/// UI-only for now — actual notification scheduling will be implemented later.
class NotificationToggles extends StatelessWidget {
  final AppSettingsState settings;
  final void Function(String key, bool value) onToggle;

  const NotificationToggles({
    super.key,
    required this.settings,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A45) : const Color(0xFFFAF8F3);
    final borderColor = isDark ? const Color(0xFF3A3A55) : const Color(0xFFE8E4DB);
    final textColor = isDark ? const Color(0xFFE8E6E3) : const Color(0xFF1A1A1A);
    final secondaryText = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5A5A5A);
    final activeColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF1B5E20);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Prayer notifications header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Icon(Icons.mosque_outlined, size: 18, color: secondaryText),
                const SizedBox(width: 8),
                Text(
                  'تنبيهات الصلاة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          _NotificationTile(
            title: 'الفجر',
            value: settings.notifyFajr,
            onChanged: (v) => onToggle('fajr', v),
            textColor: textColor,
            activeColor: activeColor,
          ),
          _buildDivider(borderColor),
          _NotificationTile(
            title: 'الظهر',
            value: settings.notifyDhuhr,
            onChanged: (v) => onToggle('dhuhr', v),
            textColor: textColor,
            activeColor: activeColor,
          ),
          _buildDivider(borderColor),
          _NotificationTile(
            title: 'العصر',
            value: settings.notifyAsr,
            onChanged: (v) => onToggle('asr', v),
            textColor: textColor,
            activeColor: activeColor,
          ),
          _buildDivider(borderColor),
          _NotificationTile(
            title: 'المغرب',
            value: settings.notifyMaghrib,
            onChanged: (v) => onToggle('maghrib', v),
            textColor: textColor,
            activeColor: activeColor,
          ),
          _buildDivider(borderColor),
          _NotificationTile(
            title: 'العشاء',
            value: settings.notifyIsha,
            onChanged: (v) => onToggle('isha', v),
            textColor: textColor,
            activeColor: activeColor,
          ),

          // Azkar reminders header
          Divider(color: borderColor, thickness: 1, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined, size: 18, color: secondaryText),
                const SizedBox(width: 8),
                Text(
                  'تذكير الأذكار',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          _NotificationTile(
            title: 'أذكار الصباح',
            value: settings.notifyMorningAzkar,
            onChanged: (v) => onToggle('morningAzkar', v),
            textColor: textColor,
            activeColor: activeColor,
          ),
          _buildDivider(borderColor),
          _NotificationTile(
            title: 'أذكار المساء',
            value: settings.notifyEveningAzkar,
            onChanged: (v) => onToggle('eveningAzkar', v),
            textColor: textColor,
            activeColor: activeColor,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: color, thickness: 0.5, height: 0.5),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textColor;
  final Color activeColor;

  const _NotificationTile({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.textColor,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 15,
            color: textColor,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
