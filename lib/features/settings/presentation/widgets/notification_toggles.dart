import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/adhan_audio_service.dart';
import '../providers/settings_provider.dart';

/// Displays a grouped list of notification toggles for prayers and Azkar reminders,
/// plus Adhan reciter selection.
class NotificationToggles extends StatelessWidget {
  final AppSettingsState settings;
  final void Function(String key, bool value) onToggle;
  final void Function(String reciterId)? onAdhanReciterChanged;
  final void Function(bool value)? onPlayAdhanChanged;

  const NotificationToggles({
    super.key,
    required this.settings,
    required this.onToggle,
    this.onAdhanReciterChanged,
    this.onPlayAdhanChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A45) : const Color(0xFFFAF8F3);
    final borderColor = isDark ? const Color(0xFF3A3A55) : const Color(0xFFE8E4DB);
    final textColor = isDark ? const Color(0xFFE8E6E3) : const Color(0xFF1A1A1A);
    final secondaryText = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5A5A5A);
    final activeColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF1B5E20);

    return Column(
      children: [
        // ── Prayer Notifications + Adhan ──
        Container(
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
              const SizedBox(height: 4),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Adhan Sound Settings ──
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.volume_up_outlined, size: 18, color: secondaryText),
                    const SizedBox(width: 8),
                    Text(
                      'صوت الأذان',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // Play Adhan toggle
              _NotificationTile(
                title: 'تشغيل الأذان مع التنبيه',
                value: settings.playAdhan,
                onChanged: (v) => onPlayAdhanChanged?.call(v),
                textColor: textColor,
                activeColor: activeColor,
              ),

              if (settings.playAdhan) ...[
                _buildDivider(borderColor),
                // Adhan reciter selector
                _AdhanReciterSelector(
                  selectedReciterId: settings.adhanReciterId,
                  onChanged: onAdhanReciterChanged,
                  textColor: textColor,
                  secondaryText: secondaryText,
                  activeColor: activeColor,
                  cardColor: cardColor,
                  borderColor: borderColor,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Azkar Reminders ──
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
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
        ),
      ],
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

/// Widget for selecting adhan reciter with preview button.
class _AdhanReciterSelector extends StatefulWidget {
  final String selectedReciterId;
  final void Function(String)? onChanged;
  final Color textColor;
  final Color secondaryText;
  final Color activeColor;
  final Color cardColor;
  final Color borderColor;

  const _AdhanReciterSelector({
    required this.selectedReciterId,
    this.onChanged,
    required this.textColor,
    required this.secondaryText,
    required this.activeColor,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  State<_AdhanReciterSelector> createState() => _AdhanReciterSelectorState();
}

class _AdhanReciterSelectorState extends State<_AdhanReciterSelector> {
  String? _previewingId;

  Future<void> _preview(String reciterId) async {
    if (_previewingId == reciterId) {
      // Stop preview
      await AdhanAudioService.instance.stop();
      setState(() => _previewingId = null);
      return;
    }
    setState(() => _previewingId = reciterId);
    await AdhanAudioService.instance.previewAdhan(reciterId);
    // Auto-clear after preview ends
    Future.delayed(const Duration(seconds: 16), () {
      if (mounted && _previewingId == reciterId) {
        setState(() => _previewingId = null);
      }
    });
  }

  @override
  void dispose() {
    AdhanAudioService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: availableAdhanReciters.map((reciter) {
        final isSelected = reciter.id == widget.selectedReciterId;
        final isPreviewing = _previewingId == reciter.id;

        return InkWell(
          onTap: () => widget.onChanged?.call(reciter.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? widget.activeColor : widget.secondaryText,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.activeColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reciter.nameAr,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: widget.textColor,
                        ),
                      ),
                      Text(
                        reciter.nameEn,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: widget.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Preview button
                GestureDetector(
                  onTap: () => _preview(reciter.id),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isPreviewing
                          ? widget.activeColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPreviewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 20,
                      color: isPreviewing ? widget.activeColor : widget.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
