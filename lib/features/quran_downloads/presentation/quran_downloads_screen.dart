import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/surah_names.dart';
import '../../../core/di/service_providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../quran_listen/domain/models/mp3quran_reciter.dart';
import '../../quran_listen/presentation/providers/quran_listen_provider.dart';
import 'providers/downloads_provider.dart';

/// Plays the offline playlist starting at [surahNumber]. If that surah isn't
/// downloaded for the active reciter, falls back to the nearest downloaded
/// item. No-op when nothing is downloaded.
Future<void> _startOfflinePlaylist(
  WidgetRef ref, {
  int? startSurah,
}) async {
  final items = await ref.read(downloadedPlaylistProvider.future);
  if (items.isEmpty) return;
  int startIndex = 0;
  if (startSurah != null) {
    final idx = items.indexWhere((it) => it.surahNumber == startSurah);
    if (idx >= 0) startIndex = idx;
  }
  await ref
      .read(listenPlayerProvider.notifier)
      .playPlaylist(items, startIndex: startIndex);
}

class QuranDownloadsScreen extends ConsumerWidget {
  const QuranDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciters = ref.watch(mp3QuranRecitersProvider);
    final downloads = ref.watch(downloadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تحميل القرآن',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (downloads.downloadedKeys.isNotEmpty)
            IconButton(
              tooltip: 'حذف الكل',
              icon: const Icon(
                Icons.delete_sweep_outlined,
                size: 20,
                color: AppColors.ink2,
              ),
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          _StorageBanner(state: downloads),
          if (downloads.downloadedKeys.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.playlist_play),
                  label: Text(
                    'تشغيل الكل بترتيب المصحف',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () => _startOfflinePlaylist(ref),
                ),
              ),
            ),
          Expanded(
            child: reciters.when(
              loading: () => const AppLoadingView(label: 'جاري تحميل القراء…'),
              error: (e, _) => AppErrorView(
                message: 'تعذّر تحميل قائمة القراء. تأكد من اتصال الإنترنت.',
                onRetry: () => ref.invalidate(mp3QuranRecitersProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const AppEmptyView(
                    message: 'لا يوجد قراء متاحون حالياً',
                    icon: Icons.record_voice_over_outlined,
                  );
                }
                return _ReciterPicker(reciters: list);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف جميع التحميلات', style: GoogleFonts.cairo()),
        content: Text(
          'سيتم حذف جميع السور التي حمّلتها. هل أنت متأكد؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(downloadsProvider.notifier).clearAll();
    }
  }
}

class _StorageBanner extends ConsumerStatefulWidget {
  final DownloadsState state;
  const _StorageBanner({required this.state});

  @override
  ConsumerState<_StorageBanner> createState() => _StorageBannerState();
}

class _StorageBannerState extends ConsumerState<_StorageBanner> {
  int? _bytes;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant _StorageBanner old) {
    super.didUpdateWidget(old);
    _refresh();
  }

  Future<void> _refresh() async {
    final b = await ref.read(surahDownloadServiceProvider).totalBytes();
    if (mounted) setState(() => _bytes = b);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.state.downloadedKeys.length;
    final sizeMb = _bytes == null ? '—' : (_bytes! / (1024 * 1024)).toStringAsFixed(1);
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, const Color(0xFF388E3C)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.download_done, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count سورة محفوظة على الجهاز',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$sizeMb ميغابايت',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReciterPicker extends ConsumerStatefulWidget {
  final List<Mp3QuranReciter> reciters;
  const _ReciterPicker({required this.reciters});

  @override
  ConsumerState<_ReciterPicker> createState() => _ReciterPickerState();
}

class _ReciterPickerState extends ConsumerState<_ReciterPicker> {
  ReciterWithMoshaf? _selection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: InkWell(
            onTap: _pickReciter,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _selection == null
                          ? 'اختر القارئ'
                          : '${_selection!.reciter.name} • ${_selection!.moshaf.name}',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _selection == null
              ? const _HintView()
              : _SurahList(selection: _selection!),
        ),
      ],
    );
  }

  Future<void> _pickReciter() async {
    final reciters = widget.reciters;
    final picked = await showModalBottomSheet<ReciterWithMoshaf>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: ListView.builder(
              itemCount: reciters.length,
              itemBuilder: (ctx, i) {
                final r = reciters[i];
                return ExpansionTile(
                  title: Text(
                    r.name,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  children: r.moshaf
                      .map<Widget>(
                        (m) => ListTile(
                          title: Text(m.name, style: GoogleFonts.cairo()),
                          subtitle: Text('${m.surahTotal} سورة'),
                          onTap: () => Navigator.pop(
                            ctx,
                            ReciterWithMoshaf(reciter: r, moshaf: m),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        );
      },
    );
    if (picked != null) setState(() => _selection = picked);
  }
}

class _HintView extends StatelessWidget {
  const _HintView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_download,
                size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'اختر قارئاً وروايةً لتحميل سوره والاستماع لها بدون إنترنت.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahList extends ConsumerWidget {
  final ReciterWithMoshaf selection;
  const _SurahList({required this.selection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);
    final surahList = selection.moshaf.surahList;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: surahList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        final surah = surahList[i];
        final name = kSurahNamesAr[surah] ?? 'سورة $surah';
        final key = ref
            .read(surahDownloadServiceProvider)
            .trackKey(selection.reciter.id, selection.moshaf.id, surah);
        final isDownloaded = downloads.downloadedKeys.contains(key);
        final active = downloads.active[key];
        return _SurahTile(
          surahNumber: surah,
          name: name,
          isDownloaded: isDownloaded,
          active: active,
          onDownload: () {
            final url = selection.getAudioUrlForSurah(surah);
            ref.read(downloadsProvider.notifier).download(
                  selection.reciter.id,
                  selection.moshaf.id,
                  surah,
                  url,
                );
          },
          onDelete: () => ref
              .read(downloadsProvider.notifier)
              .delete(selection.reciter.id, selection.moshaf.id, surah),
          onCancel: () => ref.read(downloadsProvider.notifier).cancel(key),
          onPlay: isDownloaded
              ? () => _startOfflinePlaylist(ref, startSurah: surah)
              : null,
        );
      },
    );
  }
}

class _SurahTile extends StatelessWidget {
  final int surahNumber;
  final String name;
  final bool isDownloaded;
  final ActiveDownload? active;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final VoidCallback? onPlay;

  const _SurahTile({
    required this.surahNumber,
    required this.name,
    required this.isDownloaded,
    required this.active,
    required this.onDownload,
    required this.onDelete,
    required this.onCancel,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    Widget trailing;
    if (active != null) {
      trailing = SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: active!.progress >= 0 ? active!.progress : null,
              strokeWidth: 2.5,
            ),
            IconButton(
              iconSize: 18,
              onPressed: onCancel,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );
    } else if (isDownloaded) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onPlay != null)
            IconButton(
              tooltip: 'تشغيل',
              onPressed: onPlay,
              icon: Icon(Icons.play_circle_fill,
                  color: AppColors.primary),
            ),
          IconButton(
            tooltip: 'حذف',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      );
    } else {
      trailing = IconButton(
        onPressed: onDownload,
        icon: Icon(Icons.download, color: AppColors.primary),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isDownloaded
            ? AppColors.primary.withValues(alpha: 0.08)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDownloaded
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$surahNumber',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.amiri(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
