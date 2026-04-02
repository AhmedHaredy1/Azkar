class PrayerTime {
  final String name;
  final String nameAr;
  final DateTime time;
  final bool isNext;

  const PrayerTime({
    required this.name,
    required this.nameAr,
    required this.time,
    this.isNext = false,
  });

  PrayerTime copyWith({bool? isNext}) {
    return PrayerTime(
      name: name,
      nameAr: nameAr,
      time: time,
      isNext: isNext ?? this.isNext,
    );
  }
}
