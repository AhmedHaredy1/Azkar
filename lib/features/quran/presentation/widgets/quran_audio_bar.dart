import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/playback_controls.dart';
import '../providers/quran_audio_provider.dart';
import '../providers/quran_provider.dart';
import 'reciter_picker_sheet.dart';

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
                      audioState.playingAyah?.isBismillah == true
                          ? 'البسملة'
                          : 'الآية ${_toArabicNumber(audioState.playingAyah?.ayahNumber ?? (audioState.currentAyahIndex ?? 0) + 1)} من ${_toArabicNumber(audioState.totalAyahs)}',
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

                  // Previous ayah (RTL: skipNext icon points to where prior ayah lives)
                  PlaybackIconButton(
                    icon: PlaybackIcons.skipNext,
                    color: Colors.white70,
                    tooltip: 'الآية السابقة',
                    onPressed: isActive
                        ? () => ref.read(quranAudioProvider.notifier).previousAyah()
                        : null,
                  ),

                  // Play/Pause
                  PlaybackPlayButton(
                    isPlaying: isActive,
                    isLoading: audioState.isLoading && isCurrentSurah,
                    backgroundColor: const Color(0xFFD4A017),
                    onPressed: () {
                      if (isActive) {
                        ref.read(quranAudioProvider.notifier).pause();
                      } else if (isCurrentSurah && !audioState.isPlaying) {
                        ref.read(quranAudioProvider.notifier).resume();
                      } else {
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

                  // Next ayah (RTL: skipPrevious icon points to where next ayah lives)
                  PlaybackIconButton(
                    icon: PlaybackIcons.skipPrevious,
                    color: Colors.white70,
                    tooltip: 'الآية التالية',
                    onPressed: isActive
                        ? () => ref.read(quranAudioProvider.notifier).nextAyah()
                        : null,
                  ),

                  // Stop
                  if (isCurrentSurah)
                    PlaybackIconButton(
                      icon: PlaybackIcons.stop,
                      color: Colors.white54,
                      tooltip: 'إيقاف',
                      onPressed: () =>
                          ref.read(quranAudioProvider.notifier).stop(),
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

  void _showReciterPicker(BuildContext context, WidgetRef ref) =>
      showReciterPicker(context, ref);
}
