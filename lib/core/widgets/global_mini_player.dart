import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../services/global_audio_handler.dart';
import '../theme/tokens.dart';
import 'playback_controls.dart';
import '../../features/live_radio/presentation/providers/live_radio_provider.dart';
import '../../features/quran_listen/presentation/providers/quran_listen_provider.dart';
import '../../features/quran/presentation/providers/quran_audio_provider.dart';

/// A compact mini player shown at the bottom of every screen when audio
/// is playing from any source (Quran ayah, Quran listen, live radio).
class GlobalMiniPlayer extends ConsumerWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranAudio = ref.watch(quranAudioProvider);
    final listenPlayer = ref.watch(listenPlayerProvider);
    final liveRadio = ref.watch(liveRadioProvider);

    final info = _resolveActiveAudio(quranAudio, listenPlayer, liveRadio);
    if (!info.isActive) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark ? AppColors.darkCard : Colors.white;
    final borderColor =
        isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.sheetTop,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            children: [
              _SourceArt(source: info.source),
              const SizedBox(width: AppSpacing.md),

              // ── Title & subtitle (tap to open source screen) ──
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openSource(context, info.source),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.title,
                      style: GoogleFonts.cairo(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.subtitle?.isNotEmpty == true
                          ? info.subtitle!
                          : _labelForSource(info.source),
                      style: GoogleFonts.cairo(
                        color: subtitleColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                ),
              ),

              // ── Stop ──
              PlaybackIconButton(
                icon: PlaybackIcons.stop,
                color: subtitleColor,
                tooltip: 'إيقاف',
                onPressed: () => _onStop(ref, info.source),
              ),

              // ── Primary play/pause ──
              PlaybackPlayButton(
                isPlaying: info.isPlaying,
                isLoading: info.isLoading,
                backgroundColor: scheme.primary,
                onPressed: () =>
                    _onPlayPause(ref, info.source, info.isPlaying),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSource(BuildContext context, ActiveAudioSource source) {
    switch (source) {
      case ActiveAudioSource.quranAyah:
        context.go('/quran');
      case ActiveAudioSource.quranListen:
        context.go('/quran-listen');
      case ActiveAudioSource.liveRadio:
        context.go('/live-radio');
      case ActiveAudioSource.none:
        return;
    }
  }

  String _labelForSource(ActiveAudioSource source) {
    switch (source) {
      case ActiveAudioSource.quranAyah:
        return 'تلاوة آية بآية';
      case ActiveAudioSource.quranListen:
        return 'استماع القرآن';
      case ActiveAudioSource.liveRadio:
        return 'بث مباشر';
      case ActiveAudioSource.none:
        return '';
    }
  }

  GlobalAudioInfo _resolveActiveAudio(
    QuranAudioState quranAudio,
    ListenPlayerState listenPlayer,
    LiveRadioState liveRadio,
  ) {
    // Live radio (active or paused)
    if (liveRadio.playingStationId != null && !liveRadio.isVideoMode) {
      final station = radioStations
          .where((s) => s.id == liveRadio.playingStationId)
          .firstOrNull;
      return GlobalAudioInfo(
        source: ActiveAudioSource.liveRadio,
        title: station?.nameAr ?? 'البث المباشر',
        subtitle: station?.nameEn,
        isPlaying: liveRadio.isPlaying,
        isLoading: liveRadio.isLoading,
      );
    }

    // Quran listen (full surah)
    if (listenPlayer.hasAudio) {
      return GlobalAudioInfo(
        source: ActiveAudioSource.quranListen,
        title: listenPlayer.reciterName ?? 'استمع للقرآن',
        subtitle: listenPlayer.moshafName,
        isPlaying: listenPlayer.isPlaying,
        isLoading: listenPlayer.isLoading,
      );
    }

    // Quran ayah-by-ayah
    if (quranAudio.currentSurah != null) {
      return GlobalAudioInfo(
        source: ActiveAudioSource.quranAyah,
        title: 'سورة ${quranAudio.currentSurah}',
        subtitle: quranAudio.reciter.nameAr,
        isPlaying: quranAudio.isPlaying,
        isLoading: quranAudio.isLoading,
      );
    }

    return const GlobalAudioInfo();
  }

  void _onPlayPause(WidgetRef ref, ActiveAudioSource source, bool isPlaying) {
    switch (source) {
      case ActiveAudioSource.quranAyah:
        if (isPlaying) {
          ref.read(quranAudioProvider.notifier).pause();
        } else {
          ref.read(quranAudioProvider.notifier).resume();
        }
      case ActiveAudioSource.quranListen:
        if (isPlaying) {
          ref.read(listenPlayerProvider.notifier).pause();
        } else {
          ref.read(listenPlayerProvider.notifier).resume();
        }
      case ActiveAudioSource.liveRadio:
        final state = ref.read(liveRadioProvider);
        final station = radioStations
            .where((s) => s.id == state.playingStationId)
            .firstOrNull;
        if (station != null) {
          ref
              .read(liveRadioProvider.notifier)
              .playStation(station, videoMode: false);
        }
      case ActiveAudioSource.none:
        break;
    }
  }

  void _onStop(WidgetRef ref, ActiveAudioSource source) {
    switch (source) {
      case ActiveAudioSource.quranAyah:
        ref.read(quranAudioProvider.notifier).stop();
      case ActiveAudioSource.quranListen:
        ref.read(listenPlayerProvider.notifier).stop();
      case ActiveAudioSource.liveRadio:
        ref.read(liveRadioProvider.notifier).stop();
      case ActiveAudioSource.none:
        break;
    }
  }
}

/// Rounded square art placeholder showing the audio source icon.
class _SourceArt extends StatelessWidget {
  final ActiveAudioSource source;
  const _SourceArt({required this.source});

  IconData get _icon {
    switch (source) {
      case ActiveAudioSource.quranAyah:
        return Icons.menu_book_rounded;
      case ActiveAudioSource.quranListen:
        return Icons.headphones_rounded;
      case ActiveAudioSource.liveRadio:
        return Icons.radio_rounded;
      case ActiveAudioSource.none:
        return Icons.music_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
      child: Icon(_icon, color: scheme.primary, size: 22),
    );
  }
}

