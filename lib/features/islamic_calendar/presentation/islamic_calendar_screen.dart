import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_number_utils.dart';
import '../../../core/widgets/ornaments.dart';

class IslamicEvent {
  final String name;
  final String description;
  final int hMonth;
  final int hDay;
  final IconData icon;
  const IslamicEvent({
    required this.name,
    required this.description,
    required this.hMonth,
    required this.hDay,
    required this.icon,
  });
}

const _events = <IslamicEvent>[
  IslamicEvent(
    name: 'رأس السنة الهجرية',
    description: 'اليوم الأول من شهر محرم — بداية السنة الهجرية.',
    hMonth: 1,
    hDay: 1,
    icon: Icons.celebration_outlined,
  ),
  IslamicEvent(
    name: 'يوم عاشوراء',
    description: 'العاشر من محرم — يُستحب صيامه.',
    hMonth: 1,
    hDay: 10,
    icon: Icons.water_drop_outlined,
  ),
  IslamicEvent(
    name: 'المولد النبوي',
    description: 'الثاني عشر من ربيع الأول — ذكرى مولد النبي ﷺ.',
    hMonth: 3,
    hDay: 12,
    icon: Icons.star_outline,
  ),
  IslamicEvent(
    name: 'الإسراء والمعراج',
    description: 'السابع والعشرون من رجب — ذكرى معجزة الإسراء والمعراج.',
    hMonth: 7,
    hDay: 27,
    icon: Icons.nights_stay_outlined,
  ),
  IslamicEvent(
    name: 'ليلة النصف من شعبان',
    description: 'الخامس عشر من شعبان — ليلة مباركة.',
    hMonth: 8,
    hDay: 15,
    icon: Icons.bedtime_outlined,
  ),
  IslamicEvent(
    name: 'بداية رمضان',
    description: 'أول رمضان — شهر الصيام والقرآن.',
    hMonth: 9,
    hDay: 1,
    icon: Icons.brightness_3_outlined,
  ),
  IslamicEvent(
    name: 'ليلة القدر (المتوقعة)',
    description: 'السابع والعشرون من رمضان — خير من ألف شهر.',
    hMonth: 9,
    hDay: 27,
    icon: Icons.auto_awesome_outlined,
  ),
  IslamicEvent(
    name: 'عيد الفطر',
    description: 'أول شوال — عيد الفطر المبارك.',
    hMonth: 10,
    hDay: 1,
    icon: Icons.mosque_outlined,
  ),
  IslamicEvent(
    name: 'يوم عرفة',
    description: 'التاسع من ذي الحجة — يُستحب صيامه لغير الحاج.',
    hMonth: 12,
    hDay: 9,
    icon: Icons.landscape_outlined,
  ),
  IslamicEvent(
    name: 'عيد الأضحى',
    description: 'العاشر من ذي الحجة — عيد الأضحى.',
    hMonth: 12,
    hDay: 10,
    icon: Icons.mosque_outlined,
  ),
];

const _arabicMonthNames = <String>[
  '',
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

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

final _calendarTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

class IslamicCalendarScreen extends ConsumerStatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  ConsumerState<IslamicCalendarScreen> createState() =>
      _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends ConsumerState<IslamicCalendarScreen> {
  late int _displayedYear;
  late int _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = HijriCalendar.now();
    _displayedYear = now.hYear;
    _displayedMonth = now.hMonth;
  }

  void _shiftMonth(int delta) {
    setState(() {
      var m = _displayedMonth + delta;
      var y = _displayedYear;
      while (m > 12) {
        m -= 12;
        y += 1;
      }
      while (m < 1) {
        m += 12;
        y -= 1;
      }
      _displayedMonth = m;
      _displayedYear = y;
    });
  }

  void _jumpToToday() {
    final now = HijriCalendar.now();
    setState(() {
      _displayedYear = now.hYear;
      _displayedMonth = now.hMonth;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(_calendarTickProvider);
    final today = DateTime.now();
    final hijriToday = HijriCalendar.fromDate(today);
    final upcoming = _computeUpcomingEvents(today);
    final isCurrentMonth = _displayedYear == hijriToday.hYear &&
        _displayedMonth == hijriToday.hMonth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'التقويم الهجري',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!isCurrentMonth)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: TextButton(
                onPressed: _jumpToToday,
                child: Text(
                  'اليوم',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          _HeroCard(hijri: hijriToday, gregorian: today, upcoming: upcoming),
          const SizedBox(height: AppSpacing.lg),
          _MonthNavigator(
            year: _displayedYear,
            month: _displayedMonth,
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MonthGrid(
            year: _displayedYear,
            month: _displayedMonth,
            todayHijri: hijriToday,
            events: _events,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              StarMark(
                size: 10,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'المناسبات القادمة',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...upcoming.take(6).map((u) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                child: _EventRow(
                  event: u.event,
                  daysAway: u.daysAway,
                  targetDate: u.targetDate,
                ),
              )),
        ],
      ),
    );
  }

  List<_UpcomingEvent> _computeUpcomingEvents(DateTime today) {
    final results = <_UpcomingEvent>[];
    for (final e in _events) {
      final target = _nextGregorianOccurrence(e, today);
      final days = target
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      results.add(_UpcomingEvent(
        event: e,
        daysAway: days,
        targetDate: target,
      ));
    }
    results.sort((a, b) => a.daysAway.compareTo(b.daysAway));
    return results;
  }

  DateTime _nextGregorianOccurrence(IslamicEvent e, DateTime today) {
    final hijriToday = HijriCalendar.fromDate(today);
    for (int yearOffset = 0; yearOffset <= 1; yearOffset++) {
      final h = HijriCalendar();
      h.hYear = hijriToday.hYear + yearOffset;
      h.hMonth = e.hMonth;
      h.hDay = e.hDay;
      final g = h.hijriToGregorian(h.hYear, h.hMonth, h.hDay);
      final gDay = DateTime(g.year, g.month, g.day);
      final todayDay = DateTime(today.year, today.month, today.day);
      if (!gDay.isBefore(todayDay)) return gDay;
    }
    return today;
  }
}

class _UpcomingEvent {
  final IslamicEvent event;
  final int daysAway;
  final DateTime targetDate;
  const _UpcomingEvent({
    required this.event,
    required this.daysAway,
    required this.targetDate,
  });
}

class _HeroCard extends StatelessWidget {
  final HijriCalendar hijri;
  final DateTime gregorian;
  final List<_UpcomingEvent> upcoming;
  const _HeroCard({
    required this.hijri,
    required this.gregorian,
    required this.upcoming,
  });

  @override
  Widget build(BuildContext context) {
    final nextEvent = upcoming.isEmpty ? null : upcoming.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg + 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -60,
              left: -40,
              child: GeoWatermark(
                size: 220,
                color: Colors.white,
                opacity: 0.08,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'اليوم',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const Spacer(),
                    if (nextEvent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${nextEvent.event.name} بعد ${ArabicNumberUtils.toEasternArabic(nextEvent.daysAway)} يوم',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  ArabicNumberUtils.toEasternArabic(hijri.hDay),
                  style: GoogleFonts.amiri(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_arabicMonthNames[hijri.hMonth]} ${ArabicNumberUtils.toEasternArabic(hijri.hYear)}هـ',
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ArabicNumberUtils.toEasternArabic(gregorian.day)} ${_gregorianMonthsAr[gregorian.month]} ${ArabicNumberUtils.toEasternArabic(gregorian.year)}م',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
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

class _MonthNavigator extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthNavigator({
    required this.year,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final h = HijriCalendar();
    h.hYear = year;
    h.hMonth = month;
    h.hDay = 1;
    final firstG = h.hijriToGregorian(year, month, 1);
    final lastDay = h.getDaysInMonth(year, month);
    final lastG = h.hijriToGregorian(year, month, lastDay);

    String fmtRange() {
      if (firstG.month == lastG.month && firstG.year == lastG.year) {
        return '${_gregorianMonthsAr[firstG.month]} ${ArabicNumberUtils.toEasternArabic(firstG.year)}';
      }
      if (firstG.year == lastG.year) {
        return '${_gregorianMonthsAr[firstG.month]} – ${_gregorianMonthsAr[lastG.month]} ${ArabicNumberUtils.toEasternArabic(firstG.year)}';
      }
      return '${_gregorianMonthsAr[firstG.month]} ${ArabicNumberUtils.toEasternArabic(firstG.year)} – ${_gregorianMonthsAr[lastG.month]} ${ArabicNumberUtils.toEasternArabic(lastG.year)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_right, size: 22),
            color: AppColors.ink2,
            tooltip: 'الشهر السابق',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_arabicMonthNames[month]} ${ArabicNumberUtils.toEasternArabic(year)}هـ',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fmtRange(),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_left, size: 22),
            color: AppColors.ink2,
            tooltip: 'الشهر التالي',
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final HijriCalendar todayHijri;
  final List<IslamicEvent> events;
  const _MonthGrid({
    required this.year,
    required this.month,
    required this.todayHijri,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final h = HijriCalendar();
    final daysInMonth = h.getDaysInMonth(year, month);
    final firstGregorian = h.hijriToGregorian(year, month, 1);
    final startWeekday = DateTime(firstGregorian.year, firstGregorian.month,
                firstGregorian.day)
            .weekday %
        7;

    final eventDays = <int>{
      for (final e in events)
        if (e.hMonth == month) e.hDay,
    };
    final isCurrentMonth =
        year == todayHijri.hYear && month == todayHijri.hMonth;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            Row(
              children: const ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Text(
                            d,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            ..._buildRows(
              daysInMonth: daysInMonth,
              startWeekday: startWeekday,
              eventDays: eventDays,
              isCurrentMonth: isCurrentMonth,
              todayDay: todayHijri.hDay,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows({
    required int daysInMonth,
    required int startWeekday,
    required Set<int> eventDays,
    required bool isCurrentMonth,
    required int todayDay,
  }) {
    final total = startWeekday + daysInMonth;
    final weeks = (total / 7).ceil();
    final rows = <Widget>[];
    for (int w = 0; w < weeks; w++) {
      final cells = <Widget>[];
      for (int d = 0; d < 7; d++) {
        final idx = w * 7 + d;
        final day = idx - startWeekday + 1;
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 34)));
        } else {
          final isToday = isCurrentMonth && day == todayDay;
          final hasEvent = eventDays.contains(day);
          cells.add(Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary
                      : (hasEvent ? AppColors.secondarySoft : null),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  ArabicNumberUtils.toEasternArabic(day),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? Colors.white
                        : (hasEvent ? AppColors.secondary : AppColors.ink),
                  ),
                ),
              ),
            ),
          ));
        }
      }
      rows.add(Row(children: cells));
    }
    return rows;
  }
}

class _EventRow extends StatelessWidget {
  final IslamicEvent event;
  final int daysAway;
  final DateTime targetDate;
  const _EventRow({
    required this.event,
    required this.daysAway,
    required this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    final daysLabel = daysAway == 0
        ? 'اليوم'
        : daysAway == 1
            ? 'غداً'
            : '${ArabicNumberUtils.toEasternArabic(daysAway)} يوم';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(event.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ArabicNumberUtils.toEasternArabic(targetDate.day)} ${_gregorianMonthsAr[targetDate.month]} ${ArabicNumberUtils.toEasternArabic(targetDate.year)}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 2,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondarySoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              daysLabel,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
