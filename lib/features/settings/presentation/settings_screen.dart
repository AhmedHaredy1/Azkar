import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'providers/settings_provider.dart';
import 'widgets/font_size_slider.dart';
import 'widgets/notification_toggles.dart';
import 'widgets/theme_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _calculationMethods = <String, String>{
    'UmmAlQura': 'أم القرى',
    'Egyptian': 'الهيئة المصرية',
    'MuslimWorldLeague': 'رابطة العالم الإسلامي',
    'Karachi': 'جامعة العلوم الإسلامية - كراتشي',
    'NorthAmerica': 'أمريكا الشمالية',
    'Dubai': 'دبي',
    'Kuwait': 'الكويت',
    'Qatar': 'قطر',
    'Singapore': 'سنغافورة',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptive colors based on current theme
    final primaryColor = isDark ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20);
    final textPrimary = isDark ? const Color(0xFFE8E6E3) : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5A5A5A);
    final cardColor = isDark ? const Color(0xFF2A2A45) : const Color(0xFFFAF8F3);
    final borderColor = isDark ? const Color(0xFF3A3A55) : const Color(0xFFE8E4DB);
    final appBarBg = isDark ? const Color(0xFF22223A) : const Color(0xFF1B5E20);
    final appBarFg = isDark ? const Color(0xFFE8E6E3) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appearance Section ──
            _SectionHeader(title: 'المظهر', color: textPrimary),
            const SizedBox(height: 12),

            // Theme selector
            ThemeSelector(
              currentMode: settings.themeMode,
              onChanged: (mode) {
                ref.read(settingsProvider.notifier).setThemeMode(mode);
              },
            ),
            const SizedBox(height: 20),

            // Font size slider
            FontSizeSlider(
              value: settings.fontSize,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setFontSize(value);
              },
            ),
            const SizedBox(height: 28),

            // ── Prayer Times Section ──
            _SectionHeader(title: 'مواقيت الصلاة', color: textPrimary),
            const SizedBox(height: 12),

            // Calculation method
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _calculationMethods.containsKey(settings.calculationMethod)
                      ? settings.calculationMethod
                      : 'UmmAlQura',
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                  dropdownColor: cardColor,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: textPrimary,
                  ),
                  items: _calculationMethods.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setCalculationMethod(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Location refresh button
            _LocationRefreshButton(
              settings: settings,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 28),

            // ── Notifications Section ──
            _SectionHeader(title: 'التنبيهات', color: textPrimary),
            const SizedBox(height: 12),
            NotificationToggles(
              settings: settings,
              onToggle: (key, value) {
                ref.read(settingsProvider.notifier).setNotificationToggle(key, value);
              },
            ),
            const SizedBox(height: 28),

            // ── About Section ──
            _SectionHeader(title: 'عن التطبيق', color: textPrimary),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.mosque_outlined,
                    size: 48,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'حصن المسلم',
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الإصدار 1.0.0',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تطبيق الأذكار والأدعية من الكتاب والسنة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تطوير: Ahmed Haredy',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share App
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Share.share('حمّل تطبيق حصن المسلم - أذكار وأدعية من الكتاب والسنة');
                },
                icon: const Icon(Icons.share_outlined),
                label: Text(
                  'مشاركة التطبيق',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Location refresh card with GPS re-fetch functionality.
class _LocationRefreshButton extends ConsumerStatefulWidget {
  final AppSettingsState settings;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;

  const _LocationRefreshButton({
    required this.settings,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
  });

  @override
  ConsumerState<_LocationRefreshButton> createState() => _LocationRefreshButtonState();
}

class _LocationRefreshButtonState extends ConsumerState<_LocationRefreshButton> {
  bool _isLoading = false;

  Future<void> _refreshLocation() async {
    setState(() => _isLoading = true);

    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnackBar('خدمة الموقع غير مفعّلة. يرجى تفعيلها من إعدادات الجهاز.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showSnackBar('تم رفض إذن الموقع.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnackBar('تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات الجهاز.');
        }
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Save to settings
      await ref.read(settingsProvider.notifier).setLocation(
            position.latitude,
            position.longitude,
          );

      if (mounted) {
        _showSnackBar('تم تحديث الموقع بنجاح ✓');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('حدث خطأ أثناء تحديث الموقع.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        widget.settings.latitude != null && widget.settings.longitude != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الموقع',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLocation
                      ? '${widget.settings.latitude!.toStringAsFixed(4)}, ${widget.settings.longitude!.toStringAsFixed(4)}'
                      : 'لم يتم تحديد الموقع بعد',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: widget.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: widget.primaryColor,
                  ),
                )
              : IconButton(
                  onPressed: _refreshLocation,
                  icon: Icon(
                    Icons.my_location_outlined,
                    color: widget.primaryColor,
                  ),
                  tooltip: 'تحديث الموقع',
                ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
