import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../domain/models/mushaf_type.dart';
import 'mushaf_pdf_screen.dart';
import 'providers/mushaf_provider.dart';

/// Resolves a mushaf id (from the `/mushaf-pdf/:mushafId` route) to its
/// on-disk PDF and opens [MushafPdfScreen].
///
/// Keeping the async file-path resolution here lets the PDF screen be a pure
/// GoRouter destination — deep-linkable by id + page with no `extra` payload.
class MushafPdfLoaderScreen extends ConsumerWidget {
  final String mushafId;
  final int? initialPdfPage;

  const MushafPdfLoaderScreen({
    super.key,
    required this.mushafId,
    this.initialPdfPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mushaf = getMushafById(mushafId);
    if (mushaf == null) {
      return _MissingMushafView(
        message: 'المصحف المطلوب غير معروف',
      );
    }

    return FutureBuilder<({String path, bool exists})>(
      future: () async {
        final repo = ref.read(mushafRepositoryProvider);
        final path = await repo.pathForMushaf(mushaf);
        final exists = await repo.isDownloaded(mushaf);
        return (path: path, exists: exists);
      }(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (!data.exists) {
          return _MissingMushafView(
            message: 'هذا المصحف غير محمّل على جهازك',
            showLibraryButton: true,
          );
        }
        return MushafPdfScreen(
          mushaf: mushaf,
          filePath: data.path,
          initialPdfPage: initialPdfPage ?? 0,
        );
      },
    );
  }
}

class _MissingMushafView extends StatelessWidget {
  final String message;
  final bool showLibraryButton;

  const _MissingMushafView({
    required this.message,
    this.showLibraryButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 48, color: AppColors.ink3),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 14, color: AppColors.ink2),
              ),
              if (showLibraryButton) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => context.go('/mushaf-library'),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text('مكتبة المصاحف', style: GoogleFonts.cairo()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.hairlineStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
