import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';
import 'providers/duas_provider.dart';
import 'widgets/dua_text_card.dart';

class DuaDetailScreen extends ConsumerWidget {
  final String categoryId;

  const DuaDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(duaCategoryProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: categoryAsync.when(
          data: (cat) => Text(
            cat?.nameAr ?? 'الأدعية',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          loading: () => const Text(''),
          error: (_, _) => const Text('خطأ'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        centerTitle: true,
      ),
      body: categoryAsync.when(
        data: (category) {
          if (category == null || category.duasList.isEmpty) {
            return Center(
              child: Text(
                'لا توجد أدعية في هذا القسم',
                style: GoogleFonts.cairo(fontSize: 16, color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: category.duasList.length,
            itemBuilder: (context, index) {
              return DuaTextCard(
                dua: category.duasList[index],
                index: index,
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
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'حدث خطأ',
                style: GoogleFonts.cairo(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
