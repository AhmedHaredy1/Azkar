import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/surah_names.dart';
import '../../../core/theme/tokens.dart';
import '../../quran/presentation/providers/quran_audio_provider.dart';
import '../../quran/presentation/widgets/mushaf_ayah_actions_sheet.dart';
import '../../quran/presentation/widgets/quran_audio_bar.dart';
import '../domain/models/mushaf_type.dart';
import 'providers/mushaf_provider.dart';

class MushafPdfScreen extends ConsumerStatefulWidget {
  final MushafType mushaf;
  final String filePath;
  final int initialPdfPage;

  const MushafPdfScreen({
    super.key,
    required this.mushaf,
    required this.filePath,
    this.initialPdfPage = 1,
  });

  @override
  ConsumerState<MushafPdfScreen> createState() => _MushafPdfScreenState();
}

class _MushafPdfScreenState extends ConsumerState<MushafPdfScreen> {
  PDFViewController? _pdfController;
  int _currentPdfPage = 1;
  bool _showControls = true;
  final FocusNode _focusNode = FocusNode();
  late MushafType _activeMushaf;
  final TransformationController _transformController =
      TransformationController();
  double _zoomLevel = 1.0;
  bool _isZoomedIn = false;
  // Fit-to-page is the useful minimum: the zero boundary margin keeps the
  // page anchored, so zooming below 100% would only show dead space.
  static const double _minZoom = 1.0;
  static const double _maxZoom = 4.0;
  Size _viewerSize = Size.zero;

  String _toArabicNumber(int number) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  void initState() {
    super.initState();
    _activeMushaf = widget.mushaf;
    final stored = ref.read(mushafRepositoryProvider).getLastPdfPage(_activeMushaf.id);
    final initial = widget.initialPdfPage > 1 ? widget.initialPdfPage : stored;
    _currentPdfPage = initial.clamp(1, _activeMushaf.totalPdfPages);
    _transformController.addListener(_onTransformChanged);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    _zoomLevel = scale.clamp(_minZoom, _maxZoom);
    // Pinch-zoom fires this at frame rate inside an already-animating
    // InteractiveViewer. Only rebuild the screen when the pan/swipe gating
    // flips — the live % badge and slider listen to the controller directly
    // through a ValueListenableBuilder.
    final zoomedIn = scale > 1.05;
    if (zoomedIn != _isZoomedIn) {
      setState(() => _isZoomedIn = zoomedIn);
    }
  }

  void _setZoom(double zoom) {
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    final cx = _viewerSize.width / 2;
    final cy = _viewerSize.height / 2;
    // Setting the controller value notifies _onTransformChanged, which
    // updates _zoomLevel and rebuilds if the gating threshold flips.
    _transformController.value = Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(clamped, clamped, clamped, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void _goToPdfPage(int pdfPage) {
    if (pdfPage < 1 || pdfPage > _activeMushaf.totalPdfPages) return;
    _pdfController?.setPage(pdfPage - 1);
  }

  /// Open the printed mushaf page the user asked for (١ = Al-Fatihah),
  /// translating to the raw PDF page internally.
  void _goToMushafPage(int mushafPage) {
    _goToPdfPage(_activeMushaf.pdfPageFromMushaf(mushafPage));
  }

  /// One gesture pipeline for swiping:
  /// - At fit zoom a horizontal fling turns the page directly.
  /// - While zoomed, drags pan within the page; a fling that starts with the
  ///   content already resting against the matching horizontal edge turns
  ///   the page instead — zoom level is preserved (modern-reader behavior:
  ///   pan to the edge, swipe once more to flip).
  void _handleInteractionEnd(ScaleEndDetails details) {
    final v = details.velocity.pixelsPerSecond;
    final vx = v.dx;
    // Only treat clearly horizontal flings as page turns.
    if (vx.abs() < v.dy.abs()) return;

    if (!_isZoomedIn) {
      // RTL mushaf: swiping right (positive velocity) advances.
      if (vx > 200) {
        HapticFeedback.selectionClick();
        _goToPdfPage(_currentPdfPage + 1);
      } else if (vx < -200) {
        HapticFeedback.selectionClick();
        _goToPdfPage(_currentPdfPage - 1);
      }
      return;
    }

    if (vx.abs() < 250) return;

    final m = _transformController.value;
    final scale = m.getMaxScaleOnAxis();
    final tx = m.getTranslation().x;
    final minTx = -(scale - 1) * _viewerSize.width;
    const edgeTol = 16.0;

    if (vx > 0 && tx >= -edgeTol) {
      // Left edge of the page is visible and the user keeps swiping right.
      _turnPageZoomed(toNext: true, scale: scale, minTx: minTx);
    } else if (vx < 0 && tx <= minTx + edgeTol) {
      // Right edge visible, swiping left.
      _turnPageZoomed(toNext: false, scale: scale, minTx: minTx);
    }
  }

  /// Turn the page while keeping the current zoom level. The new page is
  /// positioned so reading continues naturally: forward lands on the top-right
  /// corner (start of an RTL page), backward on the top-left (its end).
  void _turnPageZoomed({
    required bool toNext,
    required double scale,
    required double minTx,
  }) {
    final target = toNext ? _currentPdfPage + 1 : _currentPdfPage - 1;
    if (target < 1 || target > _activeMushaf.totalPdfPages) return;
    HapticFeedback.selectionClick();
    _goToPdfPage(target);
    final targetTx = toNext ? minTx : 0.0;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(targetTx, 0, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  /// Per-ayah actions for the visible page — same capability set as the
  /// text reader (listen from ayah, tafsir, copy, share, bookmark).
  void _openAyahActions() {
    HapticFeedback.selectionClick();
    showMushafAyahSheet(
      context,
      ref,
      mushafId: _activeMushaf.id,
      pdfPage: _currentPdfPage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _toggleControls,
              onLongPress: _openAyahActions,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  _viewerSize =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return InteractiveViewer(
                    transformationController: _transformController,
                    minScale: _minZoom,
                    maxScale: _maxZoom,
                    // Pan stays enabled at 1x too: with a zero boundary the
                    // page cannot move, so the viewer simply reports the
                    // fling velocity through onInteractionEnd, which is what
                    // drives page turns. This removes the gesture-arena
                    // fight that made swiping laggier than the buttons.
                    panEnabled: true,
                    scaleEnabled: true,
                    // Zero margin keeps the zoomed page anchored to the
                    // screen instead of letting it be dragged anywhere.
                    boundaryMargin: EdgeInsets.zero,
                    onInteractionEnd: _handleInteractionEnd,
                    child: PDFView(
                      key: ValueKey(_activeMushaf.id),
                      filePath: widget.filePath,
                      defaultPage: _currentPdfPage - 1,
                      swipeHorizontal: true,
                      enableSwipe: false,
                      pageSnap: true,
                      autoSpacing: false,
                      pageFling: false,
                      fitPolicy: FitPolicy.BOTH,
                      fitEachPage: true,
                      onRender: (_) {},
                      onPageChanged: (page, total) {
                        if (page == null) return;
                        final pdfPage = (page + 1)
                            .clamp(1, _activeMushaf.totalPdfPages);
                        setState(() => _currentPdfPage = pdfPage);
                        ref
                            .read(mushafRepositoryProvider)
                            .setLastPdfPage(_activeMushaf.id, pdfPage);
                        ref
                            .read(lastPdfPageProvider(_activeMushaf.id).notifier)
                            .state = pdfPage;
                      },
                      onViewCreated: (controller) {
                        _pdfController = controller;
                      },
                    ),
                  );
                },
              ),
            ),
            _buildTopBar(),
            _buildBottomBar(),
            _buildFloatingTools(),
            _buildAudioBar(),
          ],
        ),
      ),
    );
  }

  /// Same playback bar as the text reader, shown while recitation is active
  /// and the chrome is hidden (the chrome's own bars take over otherwise).
  Widget _buildAudioBar() {
    final audioActive =
        ref.watch(quranAudioProvider.select((s) => s.currentSurah != null));
    if (!audioActive || _showControls) return const SizedBox.shrink();
    final surah =
        _activeMushaf.getSurahForPage(_currentPdfPage) ?? 1;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: QuranAudioBar(
          surahNumber: surah,
          surahName: kSurahNamesAr[surah] ?? 'سورة $surah',
        ),
      ),
    );
  }

  /// Fades + slides the reader chrome in and out instead of popping it.
  /// Hidden bars ignore touches so the page underneath stays interactive.
  Widget _animatedChrome({required Widget child, required double slideY}) {
    return IgnorePointer(
      ignoring: !_showControls,
      child: AnimatedSlide(
        offset: _showControls ? Offset.zero : Offset(0, slideY),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _showControls ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: child,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: _animatedChrome(
        slideY: -0.35,
        child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              tooltip: 'رجوع',
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _activeMushaf.nameAr,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    // Printed mushaf numbering — the PDF's cover pages are
                    // hidden from the user entirely.
                    'صفحة ${_toArabicNumber(_activeMushaf.mushafPageFromPdf(_currentPdfPage))} من ${_toArabicNumber(_activeMushaf.totalMushafPages)}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.touch_app_outlined, color: Colors.white),
              tooltip: 'آيات الصفحة',
              onPressed: _openAyahActions,
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong_rounded,
                  color: Colors.white),
              tooltip: 'إعادة تعيين التكبير',
              onPressed: _resetZoom,
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
              tooltip: 'تبديل المصحف',
              onPressed: _showMushafSwitcher,
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: _animatedChrome(
        slideY: 0.35,
        child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Listens to the transform controller directly: pinch-zoom
            // updates only this row, not the whole screen.
            ValueListenableBuilder<Matrix4>(
              valueListenable: _transformController,
              builder: (context, matrix, _) {
                final zoom = matrix
                    .getMaxScaleOnAxis()
                    .clamp(_minZoom, _maxZoom);
                return Row(
                  children: [
                    Icon(Icons.zoom_out_rounded,
                        color: Colors.white70, size: 18),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Slider(
                          value: zoom,
                          min: _minZoom,
                          max: _maxZoom,
                          divisions: 12,
                          activeColor: AppColors.secondary,
                          inactiveColor: Colors.white24,
                          onChanged: _setZoom,
                        ),
                      ),
                    ),
                    Icon(Icons.zoom_in_rounded,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${(zoom * 100).round()}%',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Row(
              children: [
                Text(
                  _toArabicNumber(_activeMushaf.totalMushafPages),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Slider(
                      value: _activeMushaf
                          .mushafPageFromPdf(_currentPdfPage)
                          .toDouble(),
                      min: 1,
                      max: _activeMushaf.totalMushafPages.toDouble(),
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.white24,
                      onChanged: (val) {
                        _goToMushafPage(val.round());
                      },
                    ),
                  ),
                ),
                Text(
                  _toArabicNumber(1),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: Icons.first_page_rounded,
                  tooltip: 'الصفحة الأولى',
                  // Mushaf page ١ (Al-Fatihah), skipping the PDF cover pages.
                  onTap: () => _goToMushafPage(1),
                ),
                _ControlButton(
                  icon: Icons.navigate_before_rounded,
                  tooltip: 'الصفحة السابقة',
                  onTap: () => _goToPdfPage(_currentPdfPage - 1),
                ),
                GestureDetector(
                  onTap: _showPageJumpDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _toArabicNumber(
                          _activeMushaf.mushafPageFromPdf(_currentPdfPage)),
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                _ControlButton(
                  icon: Icons.navigate_next_rounded,
                  tooltip: 'الصفحة التالية',
                  onTap: () => _goToPdfPage(_currentPdfPage + 1),
                ),
                _ControlButton(
                  icon: Icons.last_page_rounded,
                  tooltip: 'الصفحة الأخيرة',
                  onTap: () => _goToPdfPage(_activeMushaf.totalPdfPages),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goToPdfPage(_currentPdfPage - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goToPdfPage(_currentPdfPage + 1);
    }
  }

  void _showPageJumpDialog() {
    final controller = TextEditingController();
    final totalMushaf = _activeMushaf.totalMushafPages;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'انتقل إلى صفحة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: InputDecoration(
            // The user types the printed mushaf page (١ = Al-Fatihah);
            // the PDF cover-page offset is handled internally.
            hintText: '١ - ${_toArabicNumber(totalMushaf)}',
            hintStyle: GoogleFonts.cairo(color: AppColors.ink3),
          ),
          onSubmitted: (_) => _submitPageJump(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => _submitPageJump(ctx, controller.text),
            child: Text(
              'انتقال',
              style: GoogleFonts.cairo(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _submitPageJump(BuildContext dialogCtx, String input) {
    final page = int.tryParse(input.trim());
    if (page == null ||
        page < 1 ||
        page > _activeMushaf.totalMushafPages) {
      return;
    }
    Navigator.pop(dialogCtx);
    _goToMushafPage(page);
  }

  Widget _buildFloatingTools() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 12,
      left: 12,
      child: SafeArea(
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _showToolsSheet,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showToolsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'أدوات المصحف',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: Icon(Icons.touch_app_outlined,
                    color: AppColors.primary),
                title: Text(
                  'آيات الصفحة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                subtitle: Text(
                  'استماع، تفسير، نسخ، مشاركة، علامة — كما في وضع القراءة النصي',
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: AppColors.ink3),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAyahActions();
                },
              ),
              ListTile(
                leading: Icon(Icons.zoom_in_rounded,
                    color: AppColors.primary),
                title: Text(
                  'التكبير والتصغير',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                subtitle: Text(
                  'الحالي: ${(_zoomLevel * 100).round()}%',
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: AppColors.ink3),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showZoomSheet();
                },
              ),
              ListTile(
                leading: Icon(Icons.center_focus_strong_rounded,
                    color: AppColors.primary),
                title: Text(
                  'إعادة تعيين التكبير',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _resetZoom();
                },
              ),
              ListTile(
                leading: Icon(Icons.swap_horiz_rounded,
                    color: AppColors.primary),
                title: Text(
                  'تبديل المصحف',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMushafSwitcher();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showZoomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'التكبير: ${(_zoomLevel * 100).round()}%',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.zoom_out_rounded,
                        color: AppColors.ink3, size: 20),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Slider(
                          value: _zoomLevel.clamp(_minZoom, _maxZoom),
                          min: _minZoom,
                          max: _maxZoom,
                          divisions: 12,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.hairline,
                          onChanged: (val) {
                            setLocal(() {});
                            _setZoom(val);
                          },
                        ),
                      ),
                    ),
                    Icon(Icons.zoom_in_rounded,
                        color: AppColors.ink3, size: 20),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setLocal(() {});
                        _setZoom(_zoomLevel - 0.25);
                      },
                      icon: const Icon(Icons.remove_rounded),
                      label: Text('تصغير', style: GoogleFonts.cairo()),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setLocal(() {});
                        _resetZoom();
                      },
                      icon:
                          const Icon(Icons.center_focus_strong_rounded),
                      label: Text('إعادة تعيين', style: GoogleFonts.cairo()),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setLocal(() {});
                        _setZoom(_zoomLevel + 0.25);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text('تكبير', style: GoogleFonts.cairo()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMushafSwitcher() {
    final statusAsync = ref.read(mushafDownloadStatusProvider);
    final statusMap = statusAsync.valueOrNull ?? {};

    final downloadedMushafs = availableMushafs
        .where((m) => statusMap[m.id] == true)
        .toList();

    if (downloadedMushafs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد مصاحف أخرى محمّلة',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.right,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'اختر المصحف',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final m in downloadedMushafs)
              ListTile(
                leading: Icon(
                  m.id == _activeMushaf.id
                      ? Icons.check_circle_rounded
                      : Icons.menu_book_outlined,
                  color: m.id == _activeMushaf.id
                      ? AppColors.primary
                      : AppColors.ink3,
                ),
                title: Text(
                  m.nameAr,
                  style: GoogleFonts.cairo(
                    fontWeight: m.id == _activeMushaf.id
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: AppColors.ink,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (m.id == _activeMushaf.id) return;
                  final repo = ref.read(mushafRepositoryProvider);
                  final mappedPage = repo.mapPageBetweenMushafs(
                    from: _activeMushaf,
                    to: m,
                    pdfPage: _currentPdfPage,
                  );
                  // Replace this reader with the same route for the new
                  // mushaf — the loader resolves the file path.
                  context.pushReplacement(
                      '/mushaf-pdf/${m.id}?page=$mappedPage');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _ControlButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 28),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}
