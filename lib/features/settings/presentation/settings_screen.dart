import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../features/prayer_times/presentation/providers/prayer_times_provider.dart';
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

            // ── Location Section ──
            _SectionHeader(title: 'الموقع', color: textPrimary),
            const SizedBox(height: 12),

            _LocationSettingsCard(
              settings: settings,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              primaryColor: primaryColor,
              isDark: isDark,
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
            const SizedBox(height: 28),

            // ── Notifications Section ──
            _SectionHeader(title: 'التنبيهات', color: textPrimary),
            const SizedBox(height: 12),
            NotificationToggles(
              settings: settings,
              onToggle: (key, value) {
                ref.read(settingsProvider.notifier).setNotificationToggle(key, value);
              },
              onAdhanReciterChanged: (reciterId) {
                ref.read(settingsProvider.notifier).setAdhanReciter(reciterId);
              },
              onPlayAdhanChanged: (value) {
                ref.read(settingsProvider.notifier).setPlayAdhan(value);
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

// ──────────────────────────────────────────────
// Location Settings Card
// ──────────────────────────────────────────────

class _LocationSettingsCard extends ConsumerStatefulWidget {
  final AppSettingsState settings;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final bool isDark;

  const _LocationSettingsCard({
    required this.settings,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  ConsumerState<_LocationSettingsCard> createState() =>
      _LocationSettingsCardState();
}

class _LocationSettingsCardState extends ConsumerState<_LocationSettingsCard> {
  bool _isDetecting = false;

  Future<void> _autoDetectLocation() async {
    setState(() => _isDetecting = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showSnackBar('خدمة الموقع غير مفعّلة. يرجى تفعيلها من إعدادات الجهاز.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showSnackBar('تم رفض إذن الموقع.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showSnackBar('تم رفض إذن الموقع بشكل دائم.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await ref.read(settingsProvider.notifier).setAutoDetectedLocation(
            position.latitude,
            position.longitude,
          );
      ref.invalidate(locationProvider);
      ref.invalidate(prayerTimesProvider);
      ref.invalidate(nextPrayerProvider);

      if (mounted) _showSnackBar('تم تحديد الموقع تلقائياً بنجاح');
    } catch (e) {
      if (mounted) _showSnackBar('حدث خطأ أثناء تحديد الموقع.');
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl, style: GoogleFonts.cairo(fontSize: 14)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CountryCityPickerSheet(
        onCitySelected: (city) async {
          await ref.read(settingsProvider.notifier).setLocationMode(LocationMode.manual);
          await ref.read(settingsProvider.notifier).setLocation(
                city.lat,
                city.lng,
                city: city.nameAr,
                country: city.country,
                utcOffsetHours: city.utcOffset,
              );
          ref.invalidate(locationProvider);
          ref.invalidate(prayerTimesProvider);
          ref.invalidate(nextPrayerProvider);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuto = widget.settings.locationMode == LocationMode.auto;
    final hasLocation = widget.settings.latitude != null && widget.settings.longitude != null;
    final activeColor = widget.isDark ? const Color(0xFF4CAF50) : const Color(0xFF1B5E20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        children: [
          // Auto-detect toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SwitchListTile(
              title: Text(
                'تحديد الموقع تلقائياً',
                style: GoogleFonts.cairo(fontSize: 15, color: widget.textPrimary),
              ),
              subtitle: Text(
                'استخدام GPS لتحديد الموقع',
                style: GoogleFonts.cairo(fontSize: 12, color: widget.textSecondary),
              ),
              value: isAuto,
              onChanged: (value) async {
                if (value) {
                  await _autoDetectLocation();
                } else {
                  await ref.read(settingsProvider.notifier).setLocationMode(LocationMode.manual);
                }
              },
              activeTrackColor: activeColor,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: widget.borderColor, thickness: 0.5, height: 0.5),
          ),

          // Manual city selection
          if (!isAuto)
            InkWell(
              onTap: _showCityPicker,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.location_city, color: widget.primaryColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اختيار المدينة',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.textPrimary,
                            ),
                          ),
                          if (widget.settings.cityName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${widget.settings.cityName}${widget.settings.countryName != null ? ' - ${widget.settings.countryName}' : ''}',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: widget.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else
                            Text(
                              'لم يتم اختيار مدينة بعد',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: widget.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: widget.textSecondary),
                  ],
                ),
              ),
            ),

          // Auto-detect status
          if (isAuto)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.my_location, color: widget.primaryColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الموقع الحالي',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: widget.textPrimary,
                          ),
                        ),
                        if (hasLocation)
                          Text(
                            '${widget.settings.latitude!.toStringAsFixed(4)}, ${widget.settings.longitude!.toStringAsFixed(4)}',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: widget.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isDetecting)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: widget.primaryColor,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: _autoDetectLocation,
                      icon: Icon(Icons.refresh, color: widget.primaryColor),
                      tooltip: 'إعادة تحديد الموقع',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Country/City Picker
// ──────────────────────────────────────────────

class _CityData {
  final String nameAr;
  final String nameEn;
  final String country;
  final double lat;
  final double lng;
  final double utcOffset;

  const _CityData(this.nameAr, this.nameEn, this.country, this.lat, this.lng, this.utcOffset);
}

/// All cities grouped by country.
const _citiesByCountry = <String, List<_CityData>>{
  'السعودية': [
    _CityData('مكة المكرمة', 'Mecca', 'السعودية', 21.4225, 39.8262, 3),
    _CityData('المدينة المنورة', 'Medina', 'السعودية', 24.4672, 39.6112, 3),
    _CityData('الرياض', 'Riyadh', 'السعودية', 24.7136, 46.6753, 3),
    _CityData('جدة', 'Jeddah', 'السعودية', 21.5433, 39.1728, 3),
    _CityData('الدمام', 'Dammam', 'السعودية', 26.4207, 50.0888, 3),
    _CityData('الطائف', 'Taif', 'السعودية', 21.2703, 40.4158, 3),
    _CityData('تبوك', 'Tabuk', 'السعودية', 28.3835, 36.5662, 3),
    _CityData('أبها', 'Abha', 'السعودية', 18.2164, 42.5053, 3),
    _CityData('حائل', 'Hail', 'السعودية', 27.5114, 41.7208, 3),
    _CityData('بريدة', 'Buraydah', 'السعودية', 26.3260, 43.9750, 3),
    _CityData('نجران', 'Najran', 'السعودية', 17.4933, 44.1277, 3),
    _CityData('جيزان', 'Jizan', 'السعودية', 16.8892, 42.5706, 3),
    _CityData('الخبر', 'Khobar', 'السعودية', 26.2172, 50.1971, 3),
    _CityData('ينبع', 'Yanbu', 'السعودية', 24.0895, 38.0618, 3),
  ],
  'مصر': [
    _CityData('القاهرة', 'Cairo', 'مصر', 30.0444, 31.2357, 2),
    _CityData('الإسكندرية', 'Alexandria', 'مصر', 31.2001, 29.9187, 2),
    _CityData('الجيزة', 'Giza', 'مصر', 30.0131, 31.2089, 2),
    _CityData('المنصورة', 'Mansoura', 'مصر', 31.0409, 31.3785, 2),
    _CityData('طنطا', 'Tanta', 'مصر', 30.7865, 31.0004, 2),
    _CityData('أسيوط', 'Asyut', 'مصر', 27.1783, 31.1859, 2),
    _CityData('الأقصر', 'Luxor', 'مصر', 25.6872, 32.6396, 2),
    _CityData('أسوان', 'Aswan', 'مصر', 24.0889, 32.8998, 2),
    _CityData('بورسعيد', 'Port Said', 'مصر', 31.2565, 32.2841, 2),
    _CityData('السويس', 'Suez', 'مصر', 29.9668, 32.5498, 2),
    _CityData('الزقازيق', 'Zagazig', 'مصر', 30.5877, 31.5020, 2),
    _CityData('دمياط', 'Damietta', 'مصر', 31.4175, 31.8144, 2),
    _CityData('المنيا', 'Minya', 'مصر', 28.0871, 30.7618, 2),
    _CityData('سوهاج', 'Sohag', 'مصر', 26.5591, 31.6948, 2),
    _CityData('بني سويف', 'Beni Suef', 'مصر', 29.0661, 31.0994, 2),
    _CityData('الفيوم', 'Fayoum', 'مصر', 29.3084, 30.8428, 2),
    _CityData('قنا', 'Qena', 'مصر', 26.1551, 32.7160, 2),
    _CityData('شرم الشيخ', 'Sharm El Sheikh', 'مصر', 27.9158, 34.3300, 2),
    _CityData('الغردقة', 'Hurghada', 'مصر', 27.2579, 33.8116, 2),
  ],
  'الإمارات': [
    _CityData('دبي', 'Dubai', 'الإمارات', 25.2048, 55.2708, 4),
    _CityData('أبو ظبي', 'Abu Dhabi', 'الإمارات', 24.4539, 54.3773, 4),
    _CityData('الشارقة', 'Sharjah', 'الإمارات', 25.3463, 55.4209, 4),
    _CityData('عجمان', 'Ajman', 'الإمارات', 25.4052, 55.5136, 4),
    _CityData('العين', 'Al Ain', 'الإمارات', 24.1917, 55.7606, 4),
    _CityData('رأس الخيمة', 'Ras Al Khaimah', 'الإمارات', 25.7895, 55.9432, 4),
    _CityData('الفجيرة', 'Fujairah', 'الإمارات', 25.1288, 56.3264, 4),
  ],
  'الكويت': [
    _CityData('مدينة الكويت', 'Kuwait City', 'الكويت', 29.3759, 47.9774, 3),
    _CityData('حولي', 'Hawally', 'الكويت', 29.3327, 48.0283, 3),
    _CityData('الأحمدي', 'Ahmadi', 'الكويت', 29.0769, 48.0838, 3),
    _CityData('الجهراء', 'Jahra', 'الكويت', 29.3375, 47.6581, 3),
  ],
  'قطر': [
    _CityData('الدوحة', 'Doha', 'قطر', 25.2854, 51.5310, 3),
    _CityData('الوكرة', 'Al Wakrah', 'قطر', 25.1659, 51.6030, 3),
    _CityData('الخور', 'Al Khor', 'قطر', 25.6804, 51.4969, 3),
  ],
  'البحرين': [
    _CityData('المنامة', 'Manama', 'البحرين', 26.2285, 50.5860, 3),
    _CityData('المحرق', 'Muharraq', 'البحرين', 26.2572, 50.6119, 3),
    _CityData('الرفاع', 'Riffa', 'البحرين', 26.1300, 50.5550, 3),
  ],
  'عُمان': [
    _CityData('مسقط', 'Muscat', 'عُمان', 23.5880, 58.3829, 4),
    _CityData('صلالة', 'Salalah', 'عُمان', 17.0151, 54.0924, 4),
    _CityData('صحار', 'Sohar', 'عُمان', 24.3461, 56.7354, 4),
    _CityData('نزوى', 'Nizwa', 'عُمان', 22.9333, 57.5333, 4),
  ],
  'الأردن': [
    _CityData('عمّان', 'Amman', 'الأردن', 31.9454, 35.9284, 3),
    _CityData('إربد', 'Irbid', 'الأردن', 32.5556, 35.8500, 3),
    _CityData('الزرقاء', 'Zarqa', 'الأردن', 32.0728, 36.0880, 3),
    _CityData('العقبة', 'Aqaba', 'الأردن', 29.5267, 35.0078, 3),
  ],
  'فلسطين': [
    _CityData('القدس', 'Jerusalem', 'فلسطين', 31.7683, 35.2137, 2),
    _CityData('غزة', 'Gaza', 'فلسطين', 31.5017, 34.4668, 2),
    _CityData('الخليل', 'Hebron', 'فلسطين', 31.5326, 35.0998, 2),
    _CityData('نابلس', 'Nablus', 'فلسطين', 32.2211, 35.2544, 2),
    _CityData('رام الله', 'Ramallah', 'فلسطين', 31.9038, 35.2034, 2),
  ],
  'لبنان': [
    _CityData('بيروت', 'Beirut', 'لبنان', 33.8938, 35.5018, 2),
    _CityData('طرابلس', 'Tripoli', 'لبنان', 34.4367, 35.8497, 2),
    _CityData('صيدا', 'Sidon', 'لبنان', 33.5633, 35.3714, 2),
  ],
  'سوريا': [
    _CityData('دمشق', 'Damascus', 'سوريا', 33.5138, 36.2765, 3),
    _CityData('حلب', 'Aleppo', 'سوريا', 36.2021, 37.1343, 3),
    _CityData('حمص', 'Homs', 'سوريا', 34.7324, 36.7137, 3),
  ],
  'العراق': [
    _CityData('بغداد', 'Baghdad', 'العراق', 33.3152, 44.3661, 3),
    _CityData('البصرة', 'Basra', 'العراق', 30.5085, 47.7804, 3),
    _CityData('أربيل', 'Erbil', 'العراق', 36.1912, 44.0119, 3),
    _CityData('الموصل', 'Mosul', 'العراق', 36.3350, 43.1189, 3),
    _CityData('النجف', 'Najaf', 'العراق', 32.0003, 44.3354, 3),
    _CityData('كربلاء', 'Karbala', 'العراق', 32.6160, 44.0243, 3),
  ],
  'اليمن': [
    _CityData('صنعاء', 'Sanaa', 'اليمن', 15.3694, 44.1910, 3),
    _CityData('عدن', 'Aden', 'اليمن', 12.7855, 45.0187, 3),
    _CityData('تعز', 'Taiz', 'اليمن', 13.5789, 44.0219, 3),
  ],
  'السودان': [
    _CityData('الخرطوم', 'Khartoum', 'السودان', 15.5007, 32.5599, 2),
    _CityData('أم درمان', 'Omdurman', 'السودان', 15.6445, 32.4777, 2),
    _CityData('بور سودان', 'Port Sudan', 'السودان', 19.6158, 37.2164, 2),
  ],
  'ليبيا': [
    _CityData('طرابلس', 'Tripoli', 'ليبيا', 32.8872, 13.1913, 2),
    _CityData('بنغازي', 'Benghazi', 'ليبيا', 32.1167, 20.0667, 2),
    _CityData('مصراتة', 'Misrata', 'ليبيا', 32.3754, 15.0900, 2),
  ],
  'تونس': [
    _CityData('تونس العاصمة', 'Tunis', 'تونس', 36.8065, 10.1815, 1),
    _CityData('صفاقس', 'Sfax', 'تونس', 34.7406, 10.7603, 1),
    _CityData('سوسة', 'Sousse', 'تونس', 35.8254, 10.6084, 1),
  ],
  'الجزائر': [
    _CityData('الجزائر العاصمة', 'Algiers', 'الجزائر', 36.7538, 3.0588, 1),
    _CityData('وهران', 'Oran', 'الجزائر', 35.6969, -0.6331, 1),
    _CityData('قسنطينة', 'Constantine', 'الجزائر', 36.3650, 6.6147, 1),
    _CityData('عنابة', 'Annaba', 'الجزائر', 36.9000, 7.7667, 1),
  ],
  'المغرب': [
    _CityData('الرباط', 'Rabat', 'المغرب', 34.0209, -6.8416, 1),
    _CityData('الدار البيضاء', 'Casablanca', 'المغرب', 33.5731, -7.5898, 1),
    _CityData('فاس', 'Fez', 'المغرب', 34.0181, -5.0078, 1),
    _CityData('مراكش', 'Marrakech', 'المغرب', 31.6295, -7.9811, 1),
    _CityData('طنجة', 'Tangier', 'المغرب', 35.7595, -5.8340, 1),
    _CityData('أكادير', 'Agadir', 'المغرب', 30.4278, -9.5981, 1),
  ],
  'موريتانيا': [
    _CityData('نواكشوط', 'Nouakchott', 'موريتانيا', 18.0735, -15.9582, 0),
  ],
  'الصومال': [
    _CityData('مقديشو', 'Mogadishu', 'الصومال', 2.0469, 45.3182, 3),
  ],
  'جيبوتي': [
    _CityData('جيبوتي', 'Djibouti', 'جيبوتي', 11.5721, 43.1456, 3),
  ],
  'تركيا': [
    _CityData('إسطنبول', 'Istanbul', 'تركيا', 41.0082, 28.9784, 3),
    _CityData('أنقرة', 'Ankara', 'تركيا', 39.9334, 32.8597, 3),
    _CityData('إزمير', 'Izmir', 'تركيا', 38.4237, 27.1428, 3),
    _CityData('بورصة', 'Bursa', 'تركيا', 40.1828, 29.0665, 3),
    _CityData('أنطاليا', 'Antalya', 'تركيا', 36.8969, 30.7133, 3),
  ],
  'ماليزيا': [
    _CityData('كوالالمبور', 'Kuala Lumpur', 'ماليزيا', 3.1390, 101.6869, 8),
    _CityData('جورج تاون', 'George Town', 'ماليزيا', 5.4141, 100.3288, 8),
  ],
  'إندونيسيا': [
    _CityData('جاكرتا', 'Jakarta', 'إندونيسيا', -6.2088, 106.8456, 7),
    _CityData('سورابايا', 'Surabaya', 'إندونيسيا', -7.2575, 112.7521, 7),
    _CityData('باندونغ', 'Bandung', 'إندونيسيا', -6.9175, 107.6191, 7),
  ],
  'باكستان': [
    _CityData('إسلام أباد', 'Islamabad', 'باكستان', 33.6844, 73.0479, 5),
    _CityData('كراتشي', 'Karachi', 'باكستان', 24.8607, 67.0011, 5),
    _CityData('لاهور', 'Lahore', 'باكستان', 31.5204, 74.3587, 5),
  ],
  'بريطانيا': [
    _CityData('لندن', 'London', 'بريطانيا', 51.5074, -0.1278, 0),
    _CityData('برمنغهام', 'Birmingham', 'بريطانيا', 52.4862, -1.8904, 0),
    _CityData('مانشستر', 'Manchester', 'بريطانيا', 53.4808, -2.2426, 0),
  ],
  'فرنسا': [
    _CityData('باريس', 'Paris', 'فرنسا', 48.8566, 2.3522, 1),
    _CityData('مارسيليا', 'Marseille', 'فرنسا', 43.2965, 5.3698, 1),
    _CityData('ليون', 'Lyon', 'فرنسا', 45.7640, 4.8357, 1),
  ],
  'ألمانيا': [
    _CityData('برلين', 'Berlin', 'ألمانيا', 52.5200, 13.4050, 1),
    _CityData('ميونخ', 'Munich', 'ألمانيا', 48.1351, 11.5820, 1),
    _CityData('فرانكفورت', 'Frankfurt', 'ألمانيا', 50.1109, 8.6821, 1),
  ],
  'أمريكا': [
    _CityData('نيويورك', 'New York', 'أمريكا', 40.7128, -74.0060, -5),
    _CityData('لوس أنجلوس', 'Los Angeles', 'أمريكا', 34.0522, -118.2437, -8),
    _CityData('شيكاغو', 'Chicago', 'أمريكا', 41.8781, -87.6298, -6),
    _CityData('هيوستن', 'Houston', 'أمريكا', 29.7604, -95.3698, -6),
    _CityData('ديربورن', 'Dearborn', 'أمريكا', 42.3223, -83.1763, -5),
  ],
  'كندا': [
    _CityData('تورنتو', 'Toronto', 'كندا', 43.6532, -79.3832, -5),
    _CityData('مونتريال', 'Montreal', 'كندا', 45.5017, -73.5673, -5),
    _CityData('أوتاوا', 'Ottawa', 'كندا', 45.4215, -75.6972, -5),
  ],
};

class _CountryCityPickerSheet extends StatefulWidget {
  final void Function(_CityData city) onCitySelected;

  const _CountryCityPickerSheet({required this.onCitySelected});

  @override
  State<_CountryCityPickerSheet> createState() => _CountryCityPickerSheetState();
}

class _CountryCityPickerSheetState extends State<_CountryCityPickerSheet> {
  String _searchQuery = '';
  String? _selectedCountry;

  List<MapEntry<String, List<_CityData>>> get _filteredCountries {
    if (_searchQuery.isEmpty) return _citiesByCountry.entries.toList();
    return _citiesByCountry.entries.where((entry) {
      // Match country name
      if (entry.key.contains(_searchQuery)) return true;
      // Match any city in that country
      return entry.value.any((c) =>
          c.nameAr.contains(_searchQuery) ||
          c.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  List<_CityData> get _filteredCitiesInCountry {
    if (_selectedCountry == null) return [];
    final cities = _citiesByCountry[_selectedCountry!] ?? [];
    if (_searchQuery.isEmpty) return cities;
    return cities
        .where((c) =>
            c.nameAr.contains(_searchQuery) ||
            c.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20);
    final textColor = isDark ? const Color(0xFFE8E6E3) : const Color(0xFF1A1A1A);
    final secondaryColor = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF5A5A5A);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title + back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_selectedCountry != null)
                    IconButton(
                      onPressed: () => setState(() => _selectedCountry = null),
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      color: primaryColor,
                    ),
                  Expanded(
                    child: Text(
                      _selectedCountry ?? 'اختر الدولة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_selectedCountry != null) const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: _selectedCountry != null ? 'ابحث عن مدينة...' : 'ابحث عن دولة أو مدينة...',
                  hintStyle: GoogleFonts.cairo(color: secondaryColor),
                  prefixIcon: Icon(Icons.search, color: secondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.cairo(fontSize: 15, color: textColor),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: _selectedCountry == null
                  ? _buildCountryList(scrollController, primaryColor, textColor, secondaryColor)
                  : _buildCityList(scrollController, primaryColor, textColor, secondaryColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCountryList(ScrollController controller, Color primary, Color text, Color secondary) {
    final countries = _filteredCountries;

    // If search matches specific cities, show them directly
    if (_searchQuery.isNotEmpty) {
      final allMatchingCities = <_CityData>[];
      for (final entry in _citiesByCountry.entries) {
        for (final city in entry.value) {
          if (city.nameAr.contains(_searchQuery) ||
              city.nameEn.toLowerCase().contains(_searchQuery.toLowerCase())) {
            allMatchingCities.add(city);
          }
        }
      }

      if (allMatchingCities.isNotEmpty) {
        return ListView.builder(
          controller: controller,
          itemCount: allMatchingCities.length,
          itemBuilder: (context, index) {
            final city = allMatchingCities[index];
            return ListTile(
              leading: Icon(Icons.location_on_outlined, color: primary),
              title: Text(
                city.nameAr,
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: text),
              ),
              subtitle: Text(
                '${city.country} - ${city.nameEn}',
                style: GoogleFonts.cairo(fontSize: 13, color: secondary),
              ),
              onTap: () => widget.onCitySelected(city),
            );
          },
        );
      }
    }

    return ListView.builder(
      controller: controller,
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final entry = countries[index];
        return ListTile(
          leading: Icon(Icons.flag_outlined, color: primary),
          title: Text(
            entry.key,
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: text),
          ),
          subtitle: Text(
            '${entry.value.length} مدينة',
            style: GoogleFonts.cairo(fontSize: 13, color: secondary),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: secondary),
          onTap: () => setState(() {
            _selectedCountry = entry.key;
            _searchQuery = '';
          }),
        );
      },
    );
  }

  Widget _buildCityList(ScrollController controller, Color primary, Color text, Color secondary) {
    final cities = _filteredCitiesInCountry;

    return ListView.builder(
      controller: controller,
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        return ListTile(
          leading: Icon(Icons.location_on_outlined, color: primary),
          title: Text(
            city.nameAr,
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: text),
          ),
          subtitle: Text(
            city.nameEn,
            style: GoogleFonts.cairo(fontSize: 13, color: secondary),
          ),
          onTap: () => widget.onCitySelected(city),
        );
      },
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
