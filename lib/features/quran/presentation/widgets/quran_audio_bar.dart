import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/quran_audio_provider.dart';
import '../providers/quran_provider.dart';

class QuranAudioBar extends ConsumerWidget {
  final int surahNumber;
  final String surahName;

  const QuranAudioBar({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  String _toArabicNumber(int number) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(quranAudioProvider);
    final isCurrentSurah = audioState.currentSurah == surahNumber;
    final isActive = isCurrentSurah && (audioState.isPlaying || audioState.isLoading);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810).withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ayah progress indicator
            if (isActive && audioState.totalAyahs > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'الآية ${_toArabicNumber((audioState.currentAyahIndex ?? 0) + 1)} من ${_toArabicNumber(audioState.totalAyahs)}',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFD4A017),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Progress bar for current ayah
            if (isActive && audioState.duration > Duration.zero)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFFD4A017),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: const Color(0xFFD4A017),
                    overlayColor: const Color(0xFFD4A017).withValues(alpha: 0.15),
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  ),
                  child: Slider(
                    value: audioState.position.inMilliseconds
                        .toDouble()
                        .clamp(0, audioState.duration.inMilliseconds.toDouble()),
                    max: audioState.duration.inMilliseconds.toDouble(),
                    onChanged: (v) {
                      ref
                          .read(quranAudioProvider.notifier)
                          .seekTo(Duration(milliseconds: v.round()));
                    },
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  // Reciter selector
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showReciterPicker(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              audioState.reciter.nameAr,
                              style: GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Previous ayah
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white70, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: isActive
                        ? () => ref.read(quranAudioProvider.notifier).previousAyah()
                        : null,
                    tooltip: 'الآية السابقة',
                  ),

                  // Play/Pause button
                  if (audioState.isLoading && isCurrentSurah)
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          color: Color(0xFFD4A017),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        isActive
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: const Color(0xFFD4A017),
                        size: 40,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () {
                        if (isActive) {
                          ref.read(quranAudioProvider.notifier).pause();
                        } else if (isCurrentSurah && !audioState.isPlaying) {
                          ref.read(quranAudioProvider.notifier).resume();
                        } else {
                          // Start from highlighted ayah if available
                          final highlighted = ref.read(highlightedAyahProvider);
                          if (highlighted != null && highlighted.surahNumber == surahNumber) {
                            ref.read(quranAudioProvider.notifier).playFromAyah(
                                  surahNumber, highlighted.ayahNumber);
                          } else {
                            ref.read(quranAudioProvider.notifier).playSurah(surahNumber);
                          }
                        }
                      },
                    ),

                  // Next ayah
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: isActive
                        ? () => ref.read(quranAudioProvider.notifier).nextAyah()
                        : null,
                    tooltip: 'الآية التالية',
                  ),

                  // Stop button
                  if (isCurrentSurah)
                    IconButton(
                      icon: const Icon(Icons.stop_circle_outlined,
                          color: Colors.white54, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () {
                        ref.read(quranAudioProvider.notifier).stop();
                      },
                    ),
                ],
              ),
            ),

            // Error message
            if (audioState.error != null && isCurrentSurah)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 12, right: 12),
                child: Text(
                  audioState.error!,
                  style: GoogleFonts.cairo(
                    color: Colors.redAccent,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showReciterPicker(BuildContext context, WidgetRef ref) {
    final currentReciterId = ref.read(quranAudioProvider).reciterId;
    // Capture the notifier before showing the sheet to avoid using ref
    // after the parent widget is disposed.
    final audioNotifier = ref.read(quranAudioProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C1810),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'اختر القارئ',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFD4A017),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ...availableReciters.map((reciter) {
                final isSelected = reciter.id == currentReciterId;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? const Color(0xFFD4A017) : Colors.white54,
                    size: 20,
                  ),
                  title: Text(
                    reciter.nameAr,
                    style: GoogleFonts.cairo(
                      color: isSelected ? const Color(0xFFD4A017) : Colors.white,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    reciter.nameEn,
                    style: GoogleFonts.cairo(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    audioNotifier.setReciter(reciter.id);
                    Navigator.pop(sheetContext);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
