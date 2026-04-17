import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/playback_controls.dart';
import '../domain/models/mp3quran_reciter.dart';
import 'providers/quran_listen_provider.dart';

class QuranListenScreen extends ConsumerWidget {
  const QuranListenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(listenFilterProvider);
    final surahNamesAsync = ref.watch(surahNamesProvider);
    final filteredAsync = ref.watch(filteredRecitersProvider);
    final moshafTypesAsync = ref.watch(moshafTypesForSurahProvider);
    final playerState = ref.watch(listenPlayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'استمع للقرآن',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Surah selector
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: surahNamesAsync.when(
              data: (surahNames) => _SurahDropdown(
                surahNames: surahNames,
                selectedSurah: filter.selectedSurah,
                onChanged: (surah) {
                  ref.read(listenFilterProvider.notifier).setSurah(surah);
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (_, _) => const SizedBox(),
            ),
          ),

          // Moshaf type filter chips
          moshafTypesAsync.when(
            data: (types) {
              if (types.length <= 1) return const SizedBox();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      _MoshafChip(
                        label: 'الكل',
                        selected: filter.selectedMoshafType == null,
                        onTap: () {
                          ref
                              .read(listenFilterProvider.notifier)
                              .setMoshafType(null);
                        },
                      ),
                      ...types.map((type) => _MoshafChip(
                            label: moshafTypeNames[type] ?? 'نوع $type',
                            selected: filter.selectedMoshafType == type,
                            onTap: () {
                              ref
                                  .read(listenFilterProvider.notifier)
                                  .setMoshafType(type);
                            },
                          )),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
          ),

          // Reciters list
          Expanded(
            child: filteredAsync.when(
              data: (reciters) {
                if (reciters.isEmpty) {
                  return Center(
                    child: Text(
                      'لا يوجد قراء لهذه السورة بهذا المصحف',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: reciters.length,
                  itemBuilder: (context, index) {
                    final rwm = reciters[index];
                    final isCurrentlyPlaying = playerState.hasAudio &&
                        playerState.reciterName == rwm.reciter.name &&
                        playerState.moshafName == rwm.moshaf.name &&
                        playerState.surahNumber == filter.selectedSurah;

                    return _ReciterTile(
                      rwm: rwm,
                      surahNumber: filter.selectedSurah,
                      isPlaying: isCurrentlyPlaying && playerState.isPlaying,
                      isLoading: isCurrentlyPlaying && playerState.isLoading,
                      onTap: () {
                        if (isCurrentlyPlaying && playerState.isPlaying) {
                          ref.read(listenPlayerProvider.notifier).pause();
                        } else if (isCurrentlyPlaying) {
                          ref.read(listenPlayerProvider.notifier).resume();
                        } else {
                          ref
                              .read(listenPlayerProvider.notifier)
                              .play(rwm, filter.selectedSurah);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'فشل تحميل القراء',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(mp3QuranRecitersProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Mini player bar
      bottomSheet: playerState.hasAudio
          ? _MiniPlayerBar(playerState: playerState)
          : null,
    );
  }
}

// ──────────────────────────────────────────────
// Surah Dropdown
// ──────────────────────────────────────────────

class _SurahDropdown extends StatelessWidget {
  final Map<int, String> surahNames;
  final int selectedSurah;
  final ValueChanged<int> onChanged;

  const _SurahDropdown({
    required this.surahNames,
    required this.selectedSurah,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedSurah,
          isExpanded: true,
          dropdownColor: const Color(0xFF2C1810),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          menuMaxHeight: 400,
          items: List.generate(114, (i) {
            final num = i + 1;
            final name = surahNames[num] ?? 'سورة $num';
            return DropdownMenuItem(
              value: num,
              child: Text(
                '$num. $name',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
              ),
            );
          }),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Moshaf Type Filter Chip
// ──────────────────────────────────────────────

class _MoshafChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoshafChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selected: selected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.cardBorder,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Reciter Tile
// ──────────────────────────────────────────────

class _ReciterTile extends StatelessWidget {
  final ReciterWithMoshaf rwm;
  final int surahNumber;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const _ReciterTile({
    required this.rwm,
    required this.surahNumber,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isPlaying
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.cardBorder,
          width: isPlaying ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            isPlaying ? Icons.volume_up : Icons.person_outline,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          rwm.reciter.name,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
            color: isPlaying ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          rwm.moshaf.name,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: AppColors.primary,
                size: 36,
              ),
        onTap: onTap,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Mini Player Bar
// ──────────────────────────────────────────────

class _MiniPlayerBar extends ConsumerWidget {
  final ListenPlayerState playerState;

  const _MiniPlayerBar({required this.playerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahNames = ref.watch(surahNamesProvider).valueOrNull ?? const {};
    final surahNum = playerState.surahNumber;
    final surahLabel = surahNum == null
        ? ''
        : 'سورة ${surahNames[surahNum] ?? surahNum}';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810),
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
            // Progress bar
            if (playerState.duration > Duration.zero)
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFD4A017),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  thumbColor: const Color(0xFFD4A017),
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                ),
                child: Slider(
                  value: playerState.position.inMilliseconds
                      .toDouble()
                      .clamp(0, playerState.duration.inMilliseconds.toDouble()),
                  max: playerState.duration.inMilliseconds.toDouble(),
                  onChanged: (v) {
                    ref
                        .read(listenPlayerProvider.notifier)
                        .seekTo(Duration(milliseconds: v.round()));
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Surah + reciter info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          surahLabel,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          playerState.reciterName ?? '',
                          style: GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Previous surah
                  PlaybackIconButton(
                    icon: PlaybackIcons.skipPrevious,
                    color: Colors.white,
                    tooltip: 'السورة السابقة',
                    onPressed: () =>
                        ref.read(listenPlayerProvider.notifier).previousSurah(),
                  ),
                  // Play/Pause
                  PlaybackPlayButton(
                    isPlaying: playerState.isPlaying,
                    isLoading: playerState.isLoading,
                    backgroundColor: const Color(0xFFD4A017),
                    onPressed: () {
                      if (playerState.isPlaying) {
                        ref.read(listenPlayerProvider.notifier).pause();
                      } else {
                        ref.read(listenPlayerProvider.notifier).resume();
                      }
                    },
                  ),
                  // Next surah
                  PlaybackIconButton(
                    icon: PlaybackIcons.skipNext,
                    color: Colors.white,
                    tooltip: 'السورة التالية',
                    onPressed: () =>
                        ref.read(listenPlayerProvider.notifier).nextSurah(),
                  ),
                  // Stop
                  PlaybackIconButton(
                    icon: PlaybackIcons.stop,
                    color: Colors.white54,
                    tooltip: 'إيقاف',
                    onPressed: () =>
                        ref.read(listenPlayerProvider.notifier).stop(),
                  ),
                ],
              ),
            ),
            // Error
            if (playerState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 12, right: 12),
                child: Text(
                  playerState.error!,
                  style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
