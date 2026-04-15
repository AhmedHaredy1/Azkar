import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/arabic_text_utils.dart';
import 'providers/live_radio_provider.dart';

class LiveRadioScreen extends ConsumerStatefulWidget {
  const LiveRadioScreen({super.key});

  @override
  ConsumerState<LiveRadioScreen> createState() => _LiveRadioScreenState();
}

class _LiveRadioScreenState extends ConsumerState<LiveRadioScreen> {
  String _searchQuery = '';
  String _selectedNationality = kAllCountries;
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final radioState = ref.watch(liveRadioProvider);
    final mp3QuranRadios = ref.watch(mp3QuranRadiosProvider);
    final favorites = ref.watch(radioFavoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final appBarBg = isDark ? const Color(0xFF22223A) : AppColors.primary;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'البث المباشر',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Video Player ──
          if (radioState.isVideoMode && radioState.playingStationId != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _VideoPlayerWidget(
                  station: radioStations.firstWhere(
                    (s) => s.id == radioState.playingStationId,
                    orElse: () => radioStations.first,
                  ),
                  onStop: () => ref.read(liveRadioProvider.notifier).stop(),
                ),
              ),
            ),

          // ── Featured Stations Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _SectionHeader(
                icon: Icons.star_rounded,
                title: 'المحطات الرئيسية',
                isDark: isDark,
              ),
            ),
          ),

          // ── Featured Station Cards ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final station = radioStations[index];
                  final isThisStation =
                      radioState.playingStationId == station.id;
                  final isPlaying = isThisStation && radioState.isPlaying;
                  final isLoading = isThisStation && radioState.isLoading;
                  final isVideoMode = isThisStation && radioState.isVideoMode;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RadioStationCard(
                      station: station,
                      isPlaying: isPlaying,
                      isLoading: isLoading,
                      isVideoMode: isVideoMode,
                      isDark: isDark,
                      onPlayAudio: () {
                        ref
                            .read(liveRadioProvider.notifier)
                            .playStation(station, videoMode: false);
                      },
                      onPlayVideo: station.hasVideo
                          ? () {
                              ref
                                  .read(liveRadioProvider.notifier)
                                  .playStation(station, videoMode: true);
                            }
                          : null,
                    ),
                  );
                },
                childCount: radioStations.length,
              ),
            ),
          ),

          // ── Reciter Radios Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: _SectionHeader(
                icon: Icons.radio_rounded,
                title: 'إذاعات القراء',
                isDark: isDark,
              ),
            ),
          ),

          // ── Search Bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SearchBar(
                isDark: isDark,
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // ── Favorites Toggle + Nationality Filter ──
          mp3QuranRadios.when(
            data: (radios) {
              final nationalities = getAvailableNationalities(radios);

              return SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Favorites toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showFavoritesOnly = !_showFavoritesOnly;
                            if (_showFavoritesOnly) {
                              _selectedNationality = kAllCountries;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _showFavoritesOnly
                                ? Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1)
                                : (isDark ? AppColors.darkCard : AppColors.card),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: _showFavoritesOnly
                                  ? Colors.amber.withValues(alpha: 0.5)
                                  : (isDark
                                      ? AppColors.darkCardBorder
                                      : AppColors.cardBorder),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showFavoritesOnly
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _showFavoritesOnly
                                    ? Colors.amber
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '$kFavorites (${favorites.length})',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: _showFavoritesOnly
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _showFavoritesOnly
                                      ? Colors.amber.shade700
                                      : (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Nationality chips
                    if (!_showFavoritesOnly)
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          itemCount: nationalities.length,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final nat = nationalities[index];
                            final isSelected = _selectedNationality == nat;
                            return GestureDetector(
                              onTap: () => setState(
                                  () => _selectedNationality = nat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.darkCard
                                          : AppColors.card),
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.darkCardBorder
                                            : AppColors.cardBorder),
                                  ),
                                ),
                                child: Text(
                                  nat,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),

          // ── Reciter Radio List ──
          mp3QuranRadios.when(
            data: (radios) {
              // Apply filters
              var filtered = radios.toList();

              // Search filter (Arabic-aware: ignores diacritics + alef/ya variants)
              if (_searchQuery.trim().isNotEmpty) {
                filtered = filtered
                    .where((r) => ArabicTextUtils.contains(r.name, _searchQuery))
                    .toList();
              }

              // Favorites filter
              if (_showFavoritesOnly) {
                filtered = filtered
                    .where((r) => favorites.contains(r.id))
                    .toList();
              }

              // Nationality filter
              if (!_showFavoritesOnly &&
                  _selectedNationality != kAllCountries) {
                filtered = filtered
                    .where((r) =>
                        getReciterNationality(r.name) ==
                        _selectedNationality)
                    .toList();
              }

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            _showFavoritesOnly
                                ? Icons.favorite_border
                                : Icons.search_off,
                            size: 40,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _showFavoritesOnly
                                ? 'لا توجد إذاعات مفضلة'
                                : 'لا توجد نتائج',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final radio = filtered[index];
                      final stationId = 'mp3quran_${radio.id}';
                      final isThisStation =
                          radioState.playingStationId == stationId;
                      final isPlaying =
                          isThisStation && radioState.isPlaying;
                      final isLoading =
                          isThisStation && radioState.isLoading;
                      final isFav = favorites.contains(radio.id);
                      final nationality = getReciterNationality(radio.name);

                      return _ReciterRadioTile(
                        radio: radio,
                        isPlaying: isPlaying,
                        isLoading: isLoading,
                        isDark: isDark,
                        isFavorite: isFav,
                        nationality: nationality,
                        onTap: () {
                          ref
                              .read(liveRadioProvider.notifier)
                              .playStation(radio.toRadioStation());
                        },
                        onFavoriteToggle: () {
                          ref
                              .read(radioFavoritesProvider.notifier)
                              .toggle(radio.id);
                        },
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.wifi_off, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'فشل تحميل الإذاعات\nتأكد من اتصال الإنترنت',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(mp3QuranRadiosProvider),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          'إعادة المحاولة',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Error Message ──
          if (radioState.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  radioState.error!,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Section Header
// ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Search Bar
// ──────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final hintColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        textDirection: TextDirection.rtl,
        onChanged: onChanged,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن قارئ...',
          hintStyle: GoogleFonts.cairo(fontSize: 14, color: hintColor),
          prefixIcon: Icon(Icons.search, color: hintColor, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Reciter Radio Tile (with favorite + nationality)
// ──────────────────────────────────────────────

class _ReciterRadioTile extends StatelessWidget {
  final Mp3QuranRadio radio;
  final bool isPlaying;
  final bool isLoading;
  final bool isDark;
  final bool isFavorite;
  final String nationality;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _ReciterRadioTile({
    required this.radio,
    required this.isPlaying,
    required this.isLoading,
    required this.isDark,
    required this.isFavorite,
    required this.nationality,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isPlaying
                  ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                  : cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isPlaying
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : borderColor,
                width: isPlaying ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                // Radio icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                    color: isPlaying ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Name + nationality
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        radio.name,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight:
                              isPlaying ? FontWeight.bold : FontWeight.w500,
                          color: isPlaying ? AppColors.primary : textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        nationality,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Favorite button
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.amber : secondaryText,
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Status
                if (isLoading)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (isPlaying)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LIVE',
                      style: GoogleFonts.cairo(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.play_circle_outline,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Video Player Widget
// ──────────────────────────────────────────────

class _VideoPlayerWidget extends StatefulWidget {
  final RadioStation station;
  final VoidCallback onStop;

  const _VideoPlayerWidget({required this.station, required this.onStop});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.station.videoUrl;
    if (url == null) return;

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await _videoController.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: true,
        isLive: true,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.secondary,
          bufferedColor: Colors.white24,
          handleColor: AppColors.secondary,
          backgroundColor: Colors.white12,
        ),
      );
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'فشل تحميل البث المرئي',
                style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Chewie(controller: _chewieController!),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'LIVE',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              widget.station.nameAr,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Radio Station Card (Featured)
// ──────────────────────────────────────────────

class _RadioStationCard extends StatelessWidget {
  final RadioStation station;
  final bool isPlaying;
  final bool isLoading;
  final bool isVideoMode;
  final bool isDark;
  final VoidCallback onPlayAudio;
  final VoidCallback? onPlayVideo;

  const _RadioStationCard({
    required this.station,
    required this.isPlaying,
    required this.isLoading,
    required this.isVideoMode,
    required this.isDark,
    required this.onPlayAudio,
    this.onPlayVideo,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: isPlaying
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                  AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.04),
                ],
              )
            : null,
        color: isPlaying ? null : cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isPlaying
              ? AppColors.primary.withValues(alpha: 0.4)
              : borderColor,
          width: isPlaying ? 2 : 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Station icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    station.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Station info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.nameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPlaying ? AppColors.primary : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          station.nameEn,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: secondaryText,
                          ),
                        ),
                        if (isPlaying) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isVideoMode ? 'VIDEO' : 'LIVE',
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Loading indicator / Play button
              if (isLoading && !isVideoMode)
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (!station.hasVideo)
                GestureDetector(
                  onTap: onPlayAudio,
                  child: Icon(
                    isPlaying ? Icons.stop_circle : Icons.play_circle_filled,
                    color: isPlaying ? Colors.red : AppColors.primary,
                    size: 42,
                  ),
                ),
            ],
          ),

          // Audio / Video toggle buttons
          if (station.hasVideo) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    icon: Icons.headphones,
                    label: 'صوت فقط',
                    isActive: isPlaying && !isVideoMode,
                    isDark: isDark,
                    onTap: onPlayAudio,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    icon: Icons.videocam,
                    label: 'بث مرئي',
                    isActive: isPlaying && isVideoMode,
                    isDark: isDark,
                    onTap: onPlayVideo,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback? onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? AppColors.primary : secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.primary : secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
