class SebhaState {
  final int currentCount;
  final int totalCount;
  final int targetCount;
  final String selectedDhikr;

  const SebhaState({
    this.currentCount = 0,
    this.totalCount = 0,
    this.targetCount = 33,
    this.selectedDhikr = 'سبحان الله',
  });

  SebhaState copyWith({
    int? currentCount,
    int? totalCount,
    int? targetCount,
    String? selectedDhikr,
  }) {
    return SebhaState(
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      targetCount: targetCount ?? this.targetCount,
      selectedDhikr: selectedDhikr ?? this.selectedDhikr,
    );
  }
}
