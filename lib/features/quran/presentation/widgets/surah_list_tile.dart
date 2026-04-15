import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/models/surah.dart';
import '../providers/quran_audio_provider.dart';

class SurahListTile extends ConsumerWidget {
  final Surah surah;
  final VoidCallback onTap;

  const SurahListTile({
    super.key,
    required this.surah,
    required this.onTap,
  });

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }

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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
        child: Row(
          children: [
            // Surah number in decorated container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  _toArabicNumber(surah.number),
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Surah name and info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameAr,
                    style: GoogleFonts.amiri(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        surah.nameEn,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isMakki
                              ? AppColors.secondary.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isMakki ? 'مكية' : 'مدنية',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isMakki ? AppColors.secondaryDark : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Ayah count
            Text(
              '${_toArabicNumber(surah.ayahCount)} آية',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Play button
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isPlayingThis
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: audioState.isLoading && audioState.currentSurah == surah.number
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        isPlayingThis ? Icons.pause : Icons.play_arrow,
                        color: AppColors.primary,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
