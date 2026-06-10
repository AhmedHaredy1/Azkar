import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../../core/widgets/ornaments.dart';
import '../../prayer_times/presentation/providers/prayer_times_provider.dart';

final _ramadanTickProvider =
    StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    yield DateTime.now();
  }
});

const _gregorianMonthsAr = <String>[
  '',
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const _iftarDuas = <Map<String, String>>[
  {
    'text':
        'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ',
    'source': 'سنن أبي داود',
  },
  {
    'text': 'اللَّهُمَّ لَكَ صُمْتُ، وَعَلَى رِزْقِكَ أَفْطَرْتُ',
    'source': 'سنن أبي داود',
  },
  {
    'text':
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ بِرَحْمَتِكَ الَّتِي وَسِعَتْ كُلَّ شَيْءٍ أَنْ تَغْفِرَ لِي',
    'source': 'سنن ابن ماجه',
  },
];

const _suhoorDua = {
  'text':
      'نَوَيْتُ صَوْمَ غَدٍ عَنْ أَدَاءِ فَرْضِ رَمَضَانَ هَذِهِ السَّنَةِ لِلَّهِ تَعَالَى',
  'source': 'دعاء مأثور',
};

const _laylatAlQadrDua = {
  'text': 'اللَّهُمَّ إِنَّكَ عَفُوٌّ كَرِيمٌ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
  'source': 'سنن الترمذي',
};

const _qiyamDua = {
  'text':
      'اللَّهُمَّ لَكَ الْحَمْدُ أَنْتَ نُورُ السَّمَاوَاتِ وَالأَرْضِ وَمَنْ فِيهِنَّ',
  'source': 'متفق عليه',
};

const _tarawihDua = {
  'text':
      'سُبْحَانَ ذِي الْمُلْكِ وَالْمَلَكُوتِ، سُبْحَانَ ذِي الْعِزَّةِ وَالْجَبَرُوتِ',
  'source': 'ذكر بين ركعات التراويح',
};

const _lastTenDua = {
  'text':
      'اللَّهُمَّ أَعِنَّا عَلَى إِحْيَاءِ لَيَالِي الْعَشْرِ الأَوَاخِرِ وَتَقَبَّلْ مِنَّا',
  'source': 'دعاء مأثور',
};

class RamadanScreen extends ConsumerWidget {
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(_ramadanTickProvider);
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final hijri = HijriCalendar.now();
    final now = tick.value ?? DateTime.now();

    final isRamadan = hijri.hMonth == 9;
    final dayOfRamadan = isRamadan ? hijri.hDay : 0;
    final isLast10 = isRamadan && dayOfRamadan >= 20;

    DateTime? fajr;
    DateTime? maghrib;
    prayerTimesAsync.whenData((times) {
      fajr = times.firstWhere(
        (p) => p.name == 'Fajr',
        orElse: () => times.first,
      ).time;
      maghrib = times.firstWhere(
        (p) => p.name == 'Maghrib',
        orElse: () => times.first,
      ).time;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'رمضان',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isRamadan)
              _IftarCountdownHero(now: now, maghrib: maghrib)
            else
              _RamadanCountdownHero(now: now, hijri: hijri),
            const SizedBox(height: AppSpacing.md + 2),
            if (isRamadan) ...[
              _DayMeter(day: dayOfRamadan),
              const SizedBox(height: AppSpacing.md + 2),
              _TodayFastingCard(
                loading: prayerTimesAsync.isLoading,
                fajr: fajr,
                maghrib: maghrib,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                title: 'أدعية وأذكار اليوم',
                subtitle: 'احرص على المداومة عليها في كل يوم',
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _DuaTile(
                title: 'دعاء الإفطار',
                icon: Icons.restaurant_outlined,
                accent: AppColors.primary,
                dua: _iftarDuas[dayOfRamadan % _iftarDuas.length],
              ),
              const SizedBox(height: AppSpacing.sm),
              _DuaTile(
                title: 'نية الصيام عند السحور',
                icon: Icons.nightlight_outlined,
                accent: const Color(0xFF4A5B7A),
                dua: _suhoorDua,
              ),
              const SizedBox(height: AppSpacing.sm),
              _DuaTile(
                title: 'ذكر بين ركعات التراويح',
                icon: Icons.menu_book_outlined,
                accent: AppColors.secondary,
                dua: _tarawihDua,
              ),
              const SizedBox(height: AppSpacing.sm),
              _DuaTile(
                title: 'دعاء قيام الليل',
                icon: Icons.nights_stay_outlined,
                accent: const Color(0xFF4A5B7A),
                dua: _qiyamDua,
              ),
              if (isLast10) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(
                  title: 'العشر الأواخر',
                  subtitle: 'أفضل ليالي السنة — اجتهد في العبادة والدعاء',
                  accent: AppColors.secondary,
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                _DuaTile(
                  title: 'دعاء ليلة القدر',
                  icon: Icons.auto_awesome_outlined,
                  accent: AppColors.secondary,
                  highlighted: true,
                  dua: _laylatAlQadrDua,
                ),
                const SizedBox(height: AppSpacing.sm),
                _DuaTile(
                  title: 'إحياء العشر الأواخر',
                  icon: Icons.star_outline,
                  accent: AppColors.secondary,
                  dua: _lastTenDua,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(title: 'قبل العيد', subtitle: null),
              const SizedBox(height: AppSpacing.sm + 2),
              const _ZakatFitrCard(),
            ] else ...[
              _SectionHeader(
                title: 'أدعية مأثورة من شهر رمضان',
                subtitle: 'تصفحها الآن لتستعد لقدوم الشهر الفضيل',
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              _DuaTile(
                title: 'دعاء الإفطار',
                icon: Icons.restaurant_outlined,
                accent: AppColors.primary,
                dua: _iftarDuas[0],
              ),
              const SizedBox(height: AppSpacing.sm),
              _DuaTile(
                title: 'دعاء ليلة القدر',
                icon: Icons.auto_awesome_outlined,
                accent: AppColors.secondary,
                dua: _laylatAlQadrDua,
              ),
              const SizedBox(height: AppSpacing.sm),
              _DuaTile(
                title: 'دعاء قيام الليل',
                icon: Icons.nights_stay_outlined,
                accent: const Color(0xFF4A5B7A),
                dua: _qiyamDua,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                title: 'استعد للشهر الكريم',
                subtitle: null,
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              const _PrepTile(
                title: 'صيام التطوع',
                body:
                    'اعتد على صيام الإثنين والخميس والأيام البيض لتهيئة نفسك لصيام رمضان.',
                icon: Icons.wb_sunny_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _PrepTile(
                title: 'ختمة القرآن',
                body:
                    'حدد وردك اليومي من القرآن واستعد لإكمال ختمة أو أكثر في رمضان.',
                icon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _PrepTile(
                title: 'قضاء ما فات',
                body:
                    'بادر بقضاء ما عليك من أيام رمضان الماضي قبل دخول الشهر الجديد.',
                icon: Icons.event_available_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showDua(
  BuildContext context,
  String title,
  Map<String, String> dua,
  Color accent,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hairlineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            dua['text'] ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 22,
              height: 1.9,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          if ((dua['source'] ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              dua['source']!,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: AppColors.ink3,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'تم',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? accent;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: accent ?? AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: Text(
              subtitle!,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                color: AppColors.ink3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _IftarCountdownHero extends StatelessWidget {
  final DateTime now;
  final DateTime? maghrib;
  const _IftarCountdownHero({required this.now, required this.maghrib});

  @override
  Widget build(BuildContext context) {
    final target = _nextMaghrib(maghrib, now);
    final diff = target != null ? target.difference(now) : Duration.zero;
    final hours = diff.inHours.clamp(0, 99);
    final minutes = diff.inMinutes.remainder(60).clamp(0, 59);
    final seconds = diff.inSeconds.remainder(60).clamp(0, 59);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: GeoWatermark(
                size: 320,
                color: AppColors.secondaryLight,
                opacity: 0.08,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StarMark(
                      size: 12,
                      color: AppColors.secondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'الإفطار بعد',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                _CountdownText(h: hours, m: minutes, s: seconds),
                const SizedBox(height: 4),
                Text(
                  maghrib != null
                      ? 'على موعد أذان المغرب ${_formatHm(maghrib!)}'
                      : 'جارٍ تحميل مواقيت الصلاة…',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _nextMaghrib(DateTime? maghrib, DateTime now) {
    if (maghrib == null) return null;
    if (maghrib.isAfter(now)) return maghrib;
    return maghrib.add(const Duration(days: 1));
  }

  String _formatHm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return ArabicNumberUtils.toEasternArabicFromString('$h:$m');
  }
}

class _RamadanCountdownHero extends StatelessWidget {
  final DateTime now;
  final HijriCalendar hijri;
  const _RamadanCountdownHero({required this.now, required this.hijri});

  @override
  Widget build(BuildContext context) {
    final nextYear = hijri.hMonth < 9 ? hijri.hYear : hijri.hYear + 1;
    final h = HijriCalendar();
    final gStart = h.hijriToGregorian(nextYear, 9, 1);
    final startDate = DateTime(gStart.year, gStart.month, gStart.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = startDate.difference(today).inDays;
    final daysDisplay = days < 0 ? 0 : days;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: GeoWatermark(
                size: 320,
                color: AppColors.secondaryLight,
                opacity: 0.08,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StarMark(
                      size: 12,
                      color: AppColors.secondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'رمضان يقترب',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      ArabicNumberUtils.toEasternArabic(daysDisplay),
                      style: GoogleFonts.cairo(
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        daysDisplay == 1 ? 'يوماً' : 'يوماً',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'على غرة رمضان ${ArabicNumberUtils.toEasternArabic(nextYear)}هـ',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الموافق تقريباً ${ArabicNumberUtils.toEasternArabic(startDate.day)} ${_gregorianMonthsAr[startDate.month]} ${ArabicNumberUtils.toEasternArabic(startDate.year)}م',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownText extends StatelessWidget {
  final int h;
  final int m;
  final int s;
  const _CountdownText({required this.h, required this.m, required this.s});

  @override
  Widget build(BuildContext context) {
    final sepColor = Colors.white.withValues(alpha: 0.4);
    final numStyle = GoogleFonts.cairo(
      fontSize: 52,
      fontWeight: FontWeight.w600,
      height: 1,
      letterSpacing: -1,
      color: Colors.white,
    );
    final sepStyle = numStyle.copyWith(color: sepColor);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: ArabicNumberUtils.toEasternArabicFromString(
                h.toString().padLeft(2, '0'),
              ),
              style: numStyle,
            ),
            TextSpan(text: ':', style: sepStyle),
            TextSpan(
              text: ArabicNumberUtils.toEasternArabicFromString(
                m.toString().padLeft(2, '0'),
              ),
              style: numStyle,
            ),
            TextSpan(text: ':', style: sepStyle),
            TextSpan(
              text: ArabicNumberUtils.toEasternArabicFromString(
                s.toString().padLeft(2, '0'),
              ),
              style: numStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayFastingCard extends StatelessWidget {
  final bool loading;
  final DateTime? fajr;
  final DateTime? maghrib;
  const _TodayFastingCard({
    required this.loading,
    required this.fajr,
    required this.maghrib,
  });

  @override
  Widget build(BuildContext context) {
    String fastingHours() {
      if (fajr == null || maghrib == null) return '—';
      final start =
          fajr!.isBefore(maghrib!) ? fajr! : fajr!.subtract(const Duration(days: 1));
      final d = maghrib!.difference(start);
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      return '${ArabicNumberUtils.toEasternArabic(h)}س ${ArabicNumberUtils.toEasternArabic(m)}د';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مواقيت الصيام اليوم',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _FastingStat(
                  icon: Icons.nightlight_outlined,
                  label: 'السحور ينتهي',
                  value: loading
                      ? '…'
                      : (fajr != null ? _formatHm(fajr!) : '—'),
                  accent: const Color(0xFF4A5B7A),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.hairline,
              ),
              Expanded(
                child: _FastingStat(
                  icon: Icons.restaurant_outlined,
                  label: 'الإفطار',
                  value: loading
                      ? '…'
                      : (maghrib != null ? _formatHm(maghrib!) : '—'),
                  accent: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.hairline,
              ),
              Expanded(
                child: _FastingStat(
                  icon: Icons.hourglass_bottom_outlined,
                  label: 'مدة الصيام',
                  value: loading ? '…' : fastingHours(),
                  accent: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return ArabicNumberUtils.toEasternArabicFromString('$h:$m');
  }
}

class _FastingStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _FastingStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _DayMeter extends StatelessWidget {
  final int day;
  const _DayMeter({required this.day});

  @override
  Widget build(BuildContext context) {
    final remaining = (30 - day).clamp(0, 30);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'يوم ${ArabicNumberUtils.toEasternArabic(day)} من ${ArabicNumberUtils.toEasternArabic(30)}',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${ArabicNumberUtils.toEasternArabic(remaining)} يوماً متبقي',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                const gap = 3.0;
                final cellSize =
                    (constraints.maxWidth - gap * 29) / 30;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: List.generate(30, (i) {
                    final completed = i < day - 1;
                    final isToday = i == day - 1;
                    final color = completed
                        ? AppColors.primary
                        : isToday
                            ? AppColors.secondary
                            : AppColors.surfaceSunk;
                    return Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Map<String, String> dua;
  final bool highlighted;

  const _DuaTile({
    required this.title,
    required this.icon,
    required this.accent,
    required this.dua,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDua(context, title, dua, accent),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: highlighted ? accent : AppColors.hairline,
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dua['text'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.amiri(
                      fontSize: 13,
                      color: AppColors.ink2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_left,
              size: 18,
              color: AppColors.ink3,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrepTile extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const _PrepTile({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    height: 1.7,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZakatFitrCard extends StatelessWidget {
  const _ZakatFitrCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.volunteer_activism_outlined,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'زكاة الفطر',
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'صاع من غالب قوت أهل البلد عن كل فرد — يُستحب إخراجها قبل صلاة العيد لتصل مستحقيها.',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    height: 1.7,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
