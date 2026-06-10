import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../domain/models/mushaf_type.dart';
import 'providers/mushaf_provider.dart';

class MushafLibraryScreen extends ConsumerWidget {
  const MushafLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(mushafDownloadStatusProvider);
    final defaultIdAsync = ref.watch(defaultMushafIdProvider);
    final actionState = ref.watch(mushafActionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'المصاحف المصورة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          tooltip: 'رجوع',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: statusAsync.when(
        data: (statusMap) {
          final defaultId = defaultIdAsync.valueOrNull;
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: availableMushafs.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final mushaf = availableMushafs[index];
              final isDownloaded = statusMap[mushaf.id] ?? false;
              final isDefault = defaultId == mushaf.id;
              final isActing = actionState.mushafId == mushaf.id &&
                  actionState.status != MushafActionStatus.idle;

              return _MushafCard(
                mushaf: mushaf,
                isDownloaded: isDownloaded,
                isDefault: isDefault,
                actionState: isActing ? actionState : null,
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'حدث خطأ في تحميل البيانات',
            style: GoogleFonts.cairo(color: AppColors.ink3),
          ),
        ),
      ),
    );
  }
}

class _MushafCard extends ConsumerWidget {
  final MushafType mushaf;
  final bool isDownloaded;
  final bool isDefault;
  final MushafActionState? actionState;

  const _MushafCard({
    required this.mushaf,
    required this.isDownloaded,
    required this.isDefault,
    this.actionState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloading =
        actionState?.status == MushafActionStatus.downloading;
    final isDeleting = actionState?.status == MushafActionStatus.deleting;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.hairline,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusIcon(isDownloaded: isDownloaded, isDefault: isDefault),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            mushaf.nameAr,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 6),
                          _Badge(label: 'الافتراضي', color: AppColors.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(isDownloaded, isDownloading, isDeleting),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: isDownloaded
                            ? AppColors.primary
                            : AppColors.ink3,
                        fontWeight: isDownloaded
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${mushaf.fileSizeMB} MB',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.ink3,
                ),
              ),
            ],
          ),
          if (mushaf.descriptionAr.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              mushaf.descriptionAr,
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.ink2),
            ),
          ],
          if (isDownloading) ...[
            const SizedBox(height: AppSpacing.md),
            _DownloadProgress(
              progress: actionState!.progress,
              receivedMB: actionState!.receivedMB,
              totalMB: actionState!.totalMB,
              onCancel: () =>
                  ref.read(mushafActionProvider.notifier).cancelDownload(),
            ),
          ],
          if (actionState?.status == MushafActionStatus.error) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'حدث خطأ أثناء التحميل',
              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.error),
            ),
          ],
          if (!isDownloading && !isDeleting) ...[
            const SizedBox(height: AppSpacing.md),
            _buildActions(context, ref),
          ],
        ],
      ),
    );
  }

  String _statusLabel(bool downloaded, bool downloading, bool deleting) {
    if (deleting) return 'جارٍ الحذف...';
    if (downloading) return 'جارٍ التحميل...';
    if (downloaded) return 'تم التحميل ✓';
    return 'غير محمّل';
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(mushafActionProvider.notifier);

    if (!isDownloaded) {
      final hasUrl = mushaf.downloadUrl.isNotEmpty;
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: hasUrl ? 'تحميل' : 'رابط التحميل غير متوفر',
              icon: hasUrl
                  ? Icons.cloud_download_rounded
                  : Icons.link_off_rounded,
              isPrimary: hasUrl,
              onTap: hasUrl
                  ? () => notifier.downloadMushaf(mushaf)
                  : null,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (!isDefault)
          Expanded(
            child: _ActionButton(
              label: 'تعيين كافتراضي',
              icon: Icons.star_rounded,
              isPrimary: true,
              onTap: () => notifier.setDefault(mushaf.id),
            ),
          ),
        if (!isDefault) const SizedBox(width: AppSpacing.sm),
        _ActionButton(
          label: 'حذف',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          onTap: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'حذف المصحف',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'هل تريد حذف ${mushaf.nameAr}؟\nيمكنك تحميله مرة أخرى في أي وقت.',
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(mushafActionProvider.notifier).deleteMushaf(mushaf);
            },
            child: Text('حذف', style: GoogleFonts.cairo(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final bool isDownloaded;
  final bool isDefault;

  const _StatusIcon({required this.isDownloaded, required this.isDefault});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDownloaded ? AppColors.primarySoft : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        isDownloaded ? Icons.menu_book_rounded : Icons.cloud_download_outlined,
        color: isDownloaded ? AppColors.primary : AppColors.ink3,
        size: 22,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  final double progress;
  final int receivedMB;
  final int totalMB;
  final VoidCallback onCancel;

  const _DownloadProgress({
    required this.progress,
    required this.receivedMB,
    required this.totalMB,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            backgroundColor: AppColors.hairline,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              totalMB > 0
                  ? '$receivedMB / $totalMB MB (${(progress * 100).round()}%)'
                  : 'جارٍ التحميل...',
              style: GoogleFonts.cairo(fontSize: 10, color: AppColors.ink3),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onCancel,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? AppColors.ink3
        : isDestructive
            ? AppColors.error
            : isPrimary
                ? AppColors.primary
                : AppColors.ink2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary && enabled
              ? AppColors.primarySoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
