import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../../quran/presentation/providers/quran_audio_provider.dart';

/// Floating recitation player for the PDF mushaf — reading-first design.
///
/// Collapsed: a compact pill with play/pause and the current ayah label.
/// Expanded: full transport (previous/next ayah, speed, stop, recitation
/// page-follow toggle) with a thin progress line. Dark glass styling keeps
/// it legible over any page without competing with the Quran content.
class PdfAudioPlayer extends ConsumerStatefulWidget {
  final bool followEnabled;
  final VoidCallback onToggleFollow;

  const PdfAudioPlayer({
    super.key,
    required this.followEnabled,
    required this.onToggleFollow,
  });

  @override
  ConsumerState<PdfAudioPlayer> createState() => _PdfAudioPlayerState();
}

class _PdfAudioPlayerState extends ConsumerState<PdfAudioPlayer> {
  bool _expanded = false;

  String get _speedLabel {
    final speed = ref.read(quranAudioProvider).speed;
    final text = speed == speed.roundToDouble()
        ? speed.toInt().toString()
        : speed.toString();
    const digits = {'0': '٠', '1': '١', '2': '٢', '5': '٥', '7': '٧', '.': '٫'};
    return '${text.split('').map((c) => digits[c] ?? c).join()}×';
  }

  String _ayahLabel(PlayingAyahInfo? info) {
    if (info == null) return 'جاري التحميل…';
    if (info.isBismillah) return 'بسم الله الرحمن الرحيم';
    final name = kSurahNamesAr[info.surahNumber] ?? 'سورة ${info.surahNumber}';
    return '$name · آية ${ArabicNumberUtils.toEasternArabic(info.ayahNumber)}';
  }

  @override
  Widget build(BuildContext context) {
    final playingAyah =
        ref.watch(quranAudioProvider.select((s) => s.playingAyah));
    final isPlaying =
        ref.watch(quranAudioProvider.select((s) => s.isPlaying));
    final isLoading =
        ref.watch(quranAudioProvider.select((s) => s.isLoading));
    // Watching speed keeps the chip label fresh after cycling.
    ref.watch(quranAudioProvider.select((s) => s.speed));

    final notifier = ref.read(quranAudioProvider.notifier);

    return Material(
      color: Colors.black.withValues(alpha: 0.80),
      borderRadius: BorderRadius.circular(_expanded ? 18 : 26),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: _expanded
            ? _buildExpanded(notifier, playingAyah, isPlaying, isLoading)
            : _buildCollapsed(notifier, playingAyah, isPlaying, isLoading),
      ),
    );
  }

  Widget _buildCollapsed(
    QuranAudioNotifier notifier,
    PlayingAyahInfo? playingAyah,
    bool isPlaying,
    bool isLoading,
  ) {
    return InkWell(
      onTap: () => setState(() => _expanded = true),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 14, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PlayPauseButton(
              isPlaying: isPlaying,
              isLoading: isLoading,
              size: 38,
              onTap: () => isPlaying ? notifier.pause() : notifier.resume(),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _ayahLabel(playingAyah),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_less_rounded,
                size: 18, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded(
    QuranAudioNotifier notifier,
    PlayingAyahInfo? playingAyah,
    bool isPlaying,
    bool isLoading,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _ayahLabel(playingAyah),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.followEnabled
                      ? Icons.my_location_rounded
                      : Icons.location_disabled_rounded,
                  size: 19,
                  color:
                      widget.followEnabled ? AppColors.secondary : Colors.white38,
                ),
                tooltip: widget.followEnabled
                    ? 'إيقاف تتبع التلاوة'
                    : 'تتبع التلاوة (قلب الصفحة تلقائيًا)',
                onPressed: widget.onToggleFollow,
              ),
              IconButton(
                icon: const Icon(Icons.expand_more_rounded,
                    size: 22, color: Colors.white54),
                tooltip: 'تصغير',
                onPressed: () => setState(() => _expanded = false),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed chip
              InkWell(
                onTap: notifier.cycleSpeed,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _speedLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded,
                    size: 30, color: Colors.white),
                tooltip: 'الآية السابقة',
                onPressed: notifier.previousAyah,
              ),
              _PlayPauseButton(
                isPlaying: isPlaying,
                isLoading: isLoading,
                size: 52,
                onTap: () => isPlaying ? notifier.pause() : notifier.resume(),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded,
                    size: 30, color: Colors.white),
                tooltip: 'الآية التالية',
                onPressed: notifier.nextAyah,
              ),
              IconButton(
                icon: const Icon(Icons.stop_rounded,
                    size: 24, color: Colors.white70),
                tooltip: 'إيقاف التلاوة',
                onPressed: notifier.stop,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Progress line — isolated so the 200ms position ticks rebuild
        // only this 3px bar, never the whole player.
        Consumer(
          builder: (context, ref, _) {
            final position =
                ref.watch(quranAudioProvider.select((s) => s.position));
            final duration =
                ref.watch(quranAudioProvider.select((s) => s.duration));
            final value = duration.inMilliseconds == 0
                ? 0.0
                : (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0);
            return SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final double size;
  final VoidCallback onTap;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.isLoading,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: isLoading
              ? Padding(
                  padding: EdgeInsets.all(size * 0.28),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: size * 0.58,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
