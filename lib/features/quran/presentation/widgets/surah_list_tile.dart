import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../domain/models/surah.dart';
import '../providers/quran_audio_provider.dart';

/// Surah row — circular numeric badge on the start; minimal right side with
/// revelation type + ayah count. Tap opens the mushaf; inline play button
/// starts/toggles surah audio.
class SurahListTile extends ConsumerWidget {
  final Surah surah;
  final VoidCallback onTap;

  const SurahListTile({
    super.key,
    required this.surah,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMakki = surah.revelationType.toLowerCase() == 'meccan' ||
        surah.revelationType == 'مكية' ||
        surah.revelationType.toLowerCase() == 'makkiyyah';

    final audioState = ref.watch(quranAudioProvider);
    final isPlayingThis = audioState.currentSurah == surah.number &&
        (audioState.isPlaying || audioState.isLoading);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 4,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline, width: 1),
              ),
              child: Text(
                ArabicNumberUtils.toEasternArabic(surah.number),
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameAr,
                    style: GoogleFonts.notoNaskhArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${isMakki ? 'مكية' : 'مدنية'} · ${ArabicNumberUtils.toEasternArabic(surah.ayahCount)} آية',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (isPlayingThis) {
                  ref.read(quranAudioProvider.notifier).pause();
                } else if (audioState.currentSurah == surah.number) {
                  ref.read(quranAudioProvider.notifier).resume();
                } else {
                  ref.read(quranAudioProvider.notifier).playSurah(surah.number);
                }
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isPlayingThis
                      ? AppColors.primary
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: audioState.isLoading &&
                        audioState.currentSurah == surah.number
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        isPlayingThis
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: isPlayingThis ? Colors.white : AppColors.primary,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
