import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../domain/models/quran_page.dart';
import '../providers/quran_audio_provider.dart';
import '../providers/quran_provider.dart';
import 'reciter_picker_sheet.dart';
import 'tafsir_sheet.dart';

/// Opens the per-ayah action sheet for a PDF mushaf page.
///
/// The printed page is resolved to its standard text-layout page (exact for
/// Madinah-layout mushafs, surah-proportional otherwise) and the page's
/// ayahs are listed from the app's Quran data. Selecting an ayah exposes the
/// same actions as the text reader: listen-from-here, tafsir, copy, share,
/// and bookmark — so both reading modes offer the same capabilities.
Future<void> showMushafAyahSheet(
  BuildContext context,
  WidgetRef ref, {
  required String mushafId,
  required int pdfPage,
}) async {
  final textPage = await ref.read(
    pdfToTextPageProvider((mushafId: mushafId, pdfPage: pdfPage)).future,
  );
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MushafAyahSheet(initialTextPage: textPage),
  );
}

class _MushafAyahSheet extends ConsumerStatefulWidget {
  final int initialTextPage;

  const _MushafAyahSheet({required this.initialTextPage});

  @override
  ConsumerState<_MushafAyahSheet> createState() => _MushafAyahSheetState();
}

class _MushafAyahSheetState extends ConsumerState<_MushafAyahSheet> {
  late int _textPage = widget.initialTextPage.clamp(1, 604);
  PageAyah? _selected;

  bool _isSelected(PageAyah ayah) =>
      _selected?.surahNumber == ayah.surahNumber &&
      _selected?.ayahNumber == ayah.ayahNumber;

  void _changePage(int delta) {
    final next = (_textPage + delta).clamp(1, 604);
    if (next == _textPage) return;
    setState(() {
      _textPage = next;
      _selected = null;
    });
  }

  String _shareText(PageAyah ayah, String surahName) {
    final n = ArabicNumberUtils.toEasternArabic(ayah.ayahNumber);
    return '${ayah.text}\n\n﴿$surahName - آية $n﴾\n\n— من تطبيق رفيق المسلم';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageIndexAsync = ref.watch(pageIndexProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.66,
      decoration: const BoxDecoration(
        color: AppColors.parchment,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hairlineStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 22),
                color: AppColors.ink2,
                tooltip: 'الصفحة السابقة',
                onPressed: () => _changePage(-1),
              ),
              Text(
                'آيات صفحة ${ArabicNumberUtils.toEasternArabic(_textPage)}',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 22),
                color: AppColors.ink2,
                tooltip: 'الصفحة التالية',
                onPressed: () => _changePage(1),
              ),
            ],
          ),
          Text(
            'اختر آية لعرض الإجراءات — استماع، تفسير، نسخ، مشاركة، علامة',
            style: GoogleFonts.cairo(fontSize: 11, color: AppColors.ink3),
          ),
          const SizedBox(height: 6),
          // Reciter quick-switch right where playback usually starts.
          InkWell(
            onTap: () => showReciterPicker(context, ref),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'القارئ: ${ref.watch(quranAudioProvider.select((s) => s.reciter.nameAr))}',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink2,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      size: 16, color: AppColors.ink3),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: pageIndexAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, _) => Center(
                child: Text(
                  'تعذّر تحميل بيانات الصفحة',
                  style: GoogleFonts.cairo(color: AppColors.ink3),
                ),
              ),
              data: (pages) {
                final page = pages[_textPage];
                if (page == null) {
                  return Center(
                    child: Text(
                      'لا توجد بيانات لهذه الصفحة',
                      style: GoogleFonts.cairo(color: AppColors.ink3),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    for (final section in page.sections) ...[
                      _SectionHeader(name: section.surahNameAr),
                      for (final ayah in section.ayahs)
                        _AyahTile(
                          ayah: ayah,
                          surahName: section.surahNameAr,
                          selected: _isSelected(ayah),
                          onTap: () => setState(() {
                            _selected = _isSelected(ayah) ? null : ayah;
                          }),
                          onListen: () => _listen(ayah),
                          onTafsir: () => _tafsir(ayah),
                          onCopy: () => _copy(ayah, section.surahNameAr),
                          onShare: () =>
                              Share.share(_shareText(ayah, section.surahNameAr)),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _listen(PageAyah ayah) {
    ref
        .read(quranAudioProvider.notifier)
        .playFromAyah(ayah.surahNumber, ayah.ayahNumber);
    Navigator.of(context).pop();
  }

  void _tafsir(PageAyah ayah) {
    showTafsirSheet(
      context,
      surah: ayah.surahNumber,
      ayah: ayah.ayahNumber,
    );
  }

  Future<void> _copy(PageAyah ayah, String surahName) async {
    await Clipboard.setData(
      ClipboardData(text: _shareText(ayah, surahName)),
    );
    if (mounted) _snack('تم نسخ الآية');
  }
}

class _SectionHeader extends StatelessWidget {
  final String name;
  const _SectionHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'سورة $name',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _AyahTile extends ConsumerWidget {
  final PageAyah ayah;
  final String surahName;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onListen;
  final VoidCallback onTafsir;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _AyahTile({
    required this.ayah,
    required this.surahName,
    required this.selected,
    required this.onTap,
    required this.onListen,
    required this.onTafsir,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(
      bookmarkProvider.select(
        (list) => list.any((b) =>
            b.surahNumber == ayah.surahNumber &&
            b.ayahNumber == ayah.ayahNumber),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? AppColors.parchmentDeep : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: selected ? AppColors.parchmentBorder : AppColors.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        ArabicNumberUtils.toEasternArabic(ayah.ayahNumber),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        ayah.text,
                        maxLines: selected ? null : 2,
                        overflow: selected ? null : TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.notoNaskhArabic(
                          fontSize: 16,
                          height: 1.8,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (isBookmarked)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: Icon(Icons.bookmark_rounded,
                            size: 16, color: AppColors.secondary),
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ActionChip(
                                icon: Icons.play_arrow_rounded,
                                label: 'استمع',
                                onTap: onListen,
                              ),
                              _ActionChip(
                                icon: Icons.menu_book_rounded,
                                label: 'تفسير',
                                onTap: onTafsir,
                              ),
                              _ActionChip(
                                icon: Icons.copy_rounded,
                                label: 'نسخ',
                                onTap: onCopy,
                              ),
                              _ActionChip(
                                icon: Icons.share_outlined,
                                label: 'مشاركة',
                                onTap: onShare,
                              ),
                              _ActionChip(
                                icon: isBookmarked
                                    ? Icons.bookmark_remove_rounded
                                    : Icons.bookmark_add_outlined,
                                label: isBookmarked ? 'إزالة' : 'علامة',
                                onTap: () => ref
                                    .read(bookmarkProvider.notifier)
                                    .toggleBookmark(
                                        ayah.surahNumber, ayah.ayahNumber),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
