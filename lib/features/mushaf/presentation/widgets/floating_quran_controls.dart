import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../../quran/presentation/providers/quran_audio_provider.dart';
import '../../../quran/presentation/providers/quran_provider.dart';

/// Display info for the ayah currently being recited (text resolved from
/// the page index so the viewer always matches playback).
typedef _AyahDisplay = ({
  int surahNumber,
  int ayahNumber,
  String surahName,
  String text,
  bool isBismillah,
});

final _playingAyahDisplayProvider = Provider<_AyahDisplay?>((ref) {
  final info = ref.watch(quranAudioProvider.select((s) => s.playingAyah));
  if (info == null) return null;
  final name = kSurahNamesAr[info.surahNumber] ?? 'سورة ${info.surahNumber}';
  if (info.isBismillah) {
    return (
      surahNumber: info.surahNumber,
      ayahNumber: info.ayahNumber,
      surahName: name,
      text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      isBismillah: true,
    );
  }
  String text = '';
  final pages = ref.watch(pageIndexProvider).valueOrNull;
  final page = pages?[info.page];
  if (page != null) {
    for (final section in page.sections) {
      if (section.surahNumber != info.surahNumber) continue;
      for (final ayah in section.ayahs) {
        if (ayah.ayahNumber == info.ayahNumber) {
          text = ayah.text;
          break;
        }
      }
    }
  }
  return (
    surahNumber: info.surahNumber,
    ayahNumber: info.ayahNumber,
    surahName: name,
    text: text,
    isBismillah: false,
  );
});

enum _PanelKind { none, audio, ayah }

/// Floating, draggable control group for the PDF mushaf reader:
/// a headphone bubble that expands into the audio transport panel
/// (auto-collapses after 5s unless pinned) and — while recitation is
/// active — an ayah bubble that opens the live current-ayah viewer.
/// Dragging either bubble moves the whole group; the position is kept
/// for the rest of the session.
class FloatingQuranControls extends ConsumerStatefulWidget {
  final bool followEnabled;
  final VoidCallback onToggleFollow;
  final Future<void> Function() onPlayCurrentPage;

  const FloatingQuranControls({
    super.key,
    required this.followEnabled,
    required this.onToggleFollow,
    required this.onPlayCurrentPage,
  });

  @override
  ConsumerState<FloatingQuranControls> createState() =>
      _FloatingQuranControlsState();
}

class _FloatingQuranControlsState
    extends ConsumerState<FloatingQuranControls> {
  /// Survives screen re-entry within the same app session.
  static Offset? _sessionPos;

  Offset? _pos;
  _PanelKind _panel = _PanelKind.none;
  bool _pinned = false;
  Timer? _collapseTimer;

  static const double _bubbleSize = 46;
  static const double _panelWidth = 304;

  @override
  void initState() {
    super.initState();
    _pos = _sessionPos;
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _openPanel(_PanelKind kind) {
    HapticFeedback.selectionClick();
    setState(() => _panel = kind);
    _restartCollapseTimer();
  }

  void _closePanel() {
    _collapseTimer?.cancel();
    if (mounted) setState(() => _panel = _PanelKind.none);
  }

  /// Auto-collapse after ~5s of no interaction; pinning disables it.
  /// Only the audio panel auto-collapses — the ayah viewer stays open
  /// for reading along until explicitly closed.
  void _restartCollapseTimer() {
    _collapseTimer?.cancel();
    if (_panel != _PanelKind.audio || _pinned) return;
    _collapseTimer = Timer(const Duration(seconds: 5), _closePanel);
  }

  void _togglePin() {
    setState(() => _pinned = !_pinned);
    _restartCollapseTimer();
  }

  void _onDrag(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final next = (_pos ?? _defaultPos(size)) + details.delta;
    setState(() => _pos = next);
    _sessionPos = next;
  }

  Offset _defaultPos(Size size) =>
      Offset(12, size.height * 0.42); // left edge, clear of both chrome bars

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final audioActive =
        ref.watch(quranAudioProvider.select((s) => s.currentSurah != null));

    // When recitation stops, the ayah viewer has nothing to show.
    if (!audioActive && _panel == _PanelKind.ayah) {
      _panel = _PanelKind.none;
    }

    final raw = _pos ?? _defaultPos(size);
    final isPanelOpen = _panel != _PanelKind.none;
    final width = isPanelOpen ? _panelWidth : _bubbleSize;
    final maxPanelHeight = _panel == _PanelKind.ayah ? 360.0 : 190.0;
    final height = isPanelOpen ? maxPanelHeight : _bubbleSize * 2 + 10;

    // Keep the group on-screen for any drag/rotation/panel size.
    final left =
        raw.dx.clamp(4.0, (size.width - width - 4).clamp(4.0, 9999.0));
    final top = raw.dy.clamp(
      media.padding.top + 8,
      (size.height - height - media.padding.bottom - 8)
          .clamp(media.padding.top + 8, 9999.0),
    );

    return Positioned(
      left: left,
      top: top,
      child: switch (_panel) {
        _PanelKind.none => _buildBubbles(audioActive),
        _PanelKind.audio => _buildAudioPanel(),
        _PanelKind.ayah => _buildAyahPanel(),
      },
    );
  }

  // ── Collapsed bubbles ──

  Widget _buildBubbles(bool audioActive) {
    return GestureDetector(
      onPanUpdate: _onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Bubble(
            icon: Icons.headphones_rounded,
            tooltip: 'التلاوة الصوتية',
            highlighted: audioActive,
            onTap: () => _openPanel(_PanelKind.audio),
          ),
          if (audioActive) ...[
            const SizedBox(height: 10),
            _Bubble(
              icon: Icons.chat_bubble_outline_rounded,
              tooltip: 'الآية الحالية',
              onTap: () => _openPanel(_PanelKind.ayah),
            ),
          ],
        ],
      ),
    );
  }

  // ── Audio transport panel ──

  Widget _buildAudioPanel() {
    final playing = ref.watch(_playingAyahDisplayProvider);
    final isPlaying = ref.watch(quranAudioProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(quranAudioProvider.select((s) => s.isLoading));
    final audioActive =
        ref.watch(quranAudioProvider.select((s) => s.currentSurah != null));
    final speed = ref.watch(quranAudioProvider.select((s) => s.speed));
    final notifier = ref.read(quranAudioProvider.notifier);

    return _PanelShell(
      width: _panelWidth,
      onInteraction: _restartCollapseTimer,
      onDrag: _onDrag,
      header: Row(
        children: [
          const Icon(Icons.headphones_rounded,
              size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              playing == null
                  ? 'التلاوة الصوتية'
                  : playing.isBismillah
                      ? 'بسم الله الرحمن الرحيم'
                      : '${playing.surahName} · آية ${ArabicNumberUtils.toEasternArabic(playing.ayahNumber)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _HeaderIcon(
            icon: _pinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,
            color: _pinned ? AppColors.secondary : Colors.white54,
            tooltip: _pinned ? 'إلغاء التثبيت' : 'تثبيت اللوحة',
            onTap: _togglePin,
          ),
          _HeaderIcon(
            icon: Icons.close_rounded,
            color: Colors.white54,
            tooltip: 'إغلاق',
            onTap: _closePanel,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SpeedChip(
                speed: speed,
                onTap: () {
                  notifier.cycleSpeed();
                  _restartCollapseTimer();
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded,
                    size: 28, color: Colors.white),
                tooltip: 'الآية السابقة',
                onPressed: audioActive ? notifier.previousAyah : null,
              ),
              _PlayPauseButton(
                isPlaying: isPlaying,
                isLoading: isLoading,
                size: 50,
                onTap: () {
                  if (isPlaying) {
                    notifier.pause();
                  } else if (audioActive) {
                    notifier.resume();
                  } else {
                    // Nothing loaded yet — recite the visible page.
                    widget.onPlayCurrentPage();
                  }
                  _restartCollapseTimer();
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded,
                    size: 28, color: Colors.white),
                tooltip: 'الآية التالية',
                onPressed: audioActive ? notifier.nextAyah : null,
              ),
              _HeaderIcon(
                icon: widget.followEnabled
                    ? Icons.my_location_rounded
                    : Icons.location_disabled_rounded,
                color: widget.followEnabled
                    ? AppColors.secondary
                    : Colors.white38,
                tooltip: widget.followEnabled
                    ? 'إيقاف تتبع التلاوة'
                    : 'تتبع التلاوة',
                onTap: () {
                  widget.onToggleFollow();
                  _restartCollapseTimer();
                },
              ),
            ],
          ),
          if (audioActive) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _ProgressLine()),
                const SizedBox(width: 8),
                _HeaderIcon(
                  icon: Icons.stop_rounded,
                  color: Colors.white70,
                  tooltip: 'إيقاف التلاوة',
                  onTap: () {
                    notifier.stop();
                    _closePanel();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Current-ayah viewer panel ──

  Widget _buildAyahPanel() {
    final playing = ref.watch(_playingAyahDisplayProvider);

    return _PanelShell(
      width: _panelWidth,
      onInteraction: () {},
      onDrag: _onDrag,
      header: Row(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              playing == null
                  ? 'الآية الحالية'
                  : '${playing.surahName} · آية ${ArabicNumberUtils.toEasternArabic(playing.ayahNumber)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _HeaderIcon(
            icon: Icons.close_rounded,
            color: Colors.white54,
            tooltip: 'إغلاق',
            onTap: _closePanel,
          ),
        ],
      ),
      child: playing == null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'لا توجد تلاوة نشطة',
                style:
                    GoogleFonts.cairo(fontSize: 12, color: Colors.white54),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      playing.text.isEmpty
                          ? '${playing.surahName} — آية ${ArabicNumberUtils.toEasternArabic(playing.ayahNumber)}'
                          : playing.text,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 17,
                        height: 1.9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!playing.isBismillah) _AyahActions(playing: playing),
              ],
            ),
    );
  }
}

// ── Pieces ──

class _Bubble extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool highlighted;
  final VoidCallback onTap;

  const _Bubble({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? AppColors.primary.withValues(alpha: 0.92)
          : Colors.black.withValues(alpha: 0.72),
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white24, width: 0.8),
      ),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, size: 21, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  final double width;
  final Widget header;
  final Widget child;
  final VoidCallback onInteraction;
  final GestureDragUpdateCallback onDrag;

  const _PanelShell({
    required this.width,
    required this.header,
    required this.child,
    required this.onInteraction,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onInteraction(),
      child: Material(
        color: Colors.black.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header doubles as the drag handle.
              GestureDetector(
                onPanUpdate: onDrag,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 4),
                  child: header,
                ),
              ),
              child,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 19, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final double speed;
  final VoidCallback onTap;

  const _SpeedChip({required this.speed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = speed == speed.roundToDouble()
        ? speed.toInt().toString()
        : speed.toString();
    const digits = {'0': '٠', '1': '١', '2': '٢', '5': '٥', '7': '٧', '.': '٫'};
    final label = '${text.split('').map((c) => digits[c] ?? c).join()}×';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
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

/// Thin progress line isolated from the rest of the panel so the frequent
/// position ticks repaint only these 3 pixels.
class _ProgressLine extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(quranAudioProvider.select((s) => s.position));
    final duration = ref.watch(quranAudioProvider.select((s) => s.duration));
    final value = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: 3,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        ),
      ),
    );
  }
}

class _AyahActions extends ConsumerWidget {
  final _AyahDisplay playing;

  const _AyahActions({required this.playing});

  String get _shareText {
    final n = ArabicNumberUtils.toEasternArabic(playing.ayahNumber);
    return '${playing.text}\n\n﴿${playing.surahName} - آية $n﴾'
        '\n\n— من تطبيق رفيق المسلم';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(
      bookmarkProvider.select(
        (list) => list.any((b) =>
            b.surahNumber == playing.surahNumber &&
            b.ayahNumber == playing.ayahNumber),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _HeaderIcon(
          icon: Icons.copy_rounded,
          color: Colors.white70,
          tooltip: 'نسخ الآية',
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: _shareText));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم نسخ الآية', style: GoogleFonts.cairo()),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        _HeaderIcon(
          icon: Icons.share_outlined,
          color: Colors.white70,
          tooltip: 'مشاركة الآية',
          onTap: () => Share.share(_shareText),
        ),
        _HeaderIcon(
          icon: isBookmarked
              ? Icons.bookmark_remove_rounded
              : Icons.bookmark_add_outlined,
          color: isBookmarked ? AppColors.secondary : Colors.white70,
          tooltip: isBookmarked ? 'إزالة العلامة' : 'إضافة علامة',
          onTap: () => ref
              .read(bookmarkProvider.notifier)
              .toggleBookmark(playing.surahNumber, playing.ayahNumber),
        ),
      ],
    );
  }
}
