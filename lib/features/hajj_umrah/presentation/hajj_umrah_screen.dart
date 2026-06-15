import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/tokens.dart';

// ──────────────────────────────────────────────
// Data Provider
// ──────────────────────────────────────────────

final hajjUmrahDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/data/hajj_umrah.json');
  return json.decode(jsonStr) as Map<String, dynamic>;
});

// ──────────────────────────────────────────────
// Main Screen
// ──────────────────────────────────────────────

class HajjUmrahScreen extends ConsumerWidget {
  const HajjUmrahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(hajjUmrahDataProvider);

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'دليل الحج والعمرة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.secondary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.cairo(fontSize: 14),
            tabs: const [
              Tab(text: 'التهيئة'),
              Tab(text: 'العمرة'),
              Tab(text: 'الحج'),
              Tab(text: 'أنواع الحج'),
              Tab(text: 'الأركان والواجبات'),
              Tab(text: 'المحظورات'),
              Tab(text: 'الأدعية'),
              Tab(text: 'زيارة المدينة'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Additive entry to the interactive ritual tracker — the guide
            // tabs below are unchanged.
            const _NusukEntryBanner(),
            Expanded(
              child: dataAsync.when(
                data: (data) => TabBarView(
            children: [
              _SectionsTab(
                data: data['preparation'] as Map<String, dynamic>,
              ),
              _RitualStepsTab(
                data: data['umrah'] as Map<String, dynamic>,
                isHajj: false,
              ),
              _RitualStepsTab(
                data: data['hajj'] as Map<String, dynamic>,
                isHajj: true,
              ),
              _HajjTypesTab(
                data: data['hajjTypes'] as Map<String, dynamic>,
              ),
              _SectionsTab(
                data: data['arkanWajibat'] as Map<String, dynamic>,
              ),
              _ProhibitionsTab(
                data: data['prohibitions'] as Map<String, dynamic>,
              ),
              _DuasTab(
                data: data['commonDuas'] as Map<String, dynamic>,
              ),
              _SectionsTab(
                data: data['madinahZiyarah'] as Map<String, dynamic>,
              ),
            ],
          ),
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, _) => Center(
            child: Text(
              'فشل تحميل البيانات',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Ritual Steps Tab (Umrah / Hajj)
// ──────────────────────────────────────────────

class _RitualStepsTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isHajj;

  const _RitualStepsTab({required this.data, required this.isHajj});

  @override
  Widget build(BuildContext context) {
    final steps = data['steps'] as List<dynamic>;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index] as Map<String, dynamic>;
        final title = step['title'] as String? ?? '';
        final description = step['description'] as String? ?? '';
        final duas = (step['duas'] as List<dynamic>?)
                ?.map((d) => d.toString())
                .toList() ??
            [];

        return _StepCard(
          stepNumber: index + 1,
          title: title,
          description: description,
          duas: duas,
          isHajj: isHajj,
          dayName: step['dayName'] as String?,
        );
      },
    );
  }
}

class _StepCard extends StatefulWidget {
  final int stepNumber;
  final String title;
  final String description;
  final List<String> duas;
  final bool isHajj;
  final String? dayName;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.duas,
    required this.isHajj,
    this.dayName,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // Step number badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.stepNumber}',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.dayName != null)
                          Text(
                            widget.dayName!,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.description,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      height: 1.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.duas.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'الأدعية المأثورة',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...widget.duas.map((dua) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Text(
                                  '• $dua',
                                  style: GoogleFonts.amiri(
                                    fontSize: 16,
                                    height: 1.8,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Hajj Types Tab
// ──────────────────────────────────────────────

class _HajjTypesTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HajjTypesTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final types = data['types'] as List<dynamic>;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(Icons.mosque, color: AppColors.primary, size: 36),
              const SizedBox(height: AppSpacing.sm),
              Text(
                data['title'] as String? ?? '',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'اختر النوع المناسب لك بناءً على ظروفك',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...types.map((type) {
          final map = type as Map<String, dynamic>;
          return _HajjTypeCard(data: map);
        }),
      ],
    );
  }
}

class _HajjTypeCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const _HajjTypeCard({required this.data});

  @override
  State<_HajjTypeCard> createState() => _HajjTypeCardState();
}

class _HajjTypeCardState extends State<_HajjTypeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] as String? ?? '';
    final icon = widget.data['icon'] as String? ?? '';
    final badge = widget.data['badge'] as String? ?? '';
    final summary = widget.data['summary'] as String? ?? '';
    final description = widget.data['description'] as String? ?? '';
    final steps =
        (widget.data['steps'] as List<dynamic>?)?.cast<String>() ?? [];
    final ruling = widget.data['ruling'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.cairo(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          summary,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      height: 1.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'الخطوات:',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...steps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                e.value,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (ruling.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.balance, size: 16,
                                  color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'الحكم الشرعي',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ruling,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              height: 1.7,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Prohibitions Tab
// ──────────────────────────────────────────────

class _ProhibitionsTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ProhibitionsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final categories = data['categories'] as List<dynamic>?;
    // Support both old format (items list) and new format (categories)
    if (categories != null) {
      return _CategorizedProhibitions(data: data, categories: categories);
    }
    // Fallback for old format
    final items = data['items'] as List<dynamic>;
    return _LegacyProhibitions(data: data, items: items);
  }
}

class _CategorizedProhibitions extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic> categories;

  const _CategorizedProhibitions({
    required this.data,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 36),
              const SizedBox(height: AppSpacing.sm),
              Text(
                data['title'] as String? ?? '',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              if (data['description'] != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data['description'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Categories
        ...categories.map((cat) {
          final catMap = cat as Map<String, dynamic>;
          final catTitle = catMap['title'] as String? ?? '';
          final items = catMap['items'] as List<dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  catTitle,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ...items.map((item) {
                final map = item as Map<String, dynamic>;
                return _ProhibitionItem(data: map);
              }),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        }),
      ],
    );
  }
}

class _ProhibitionItem extends StatefulWidget {
  final Map<String, dynamic> data;

  const _ProhibitionItem({required this.data});

  @override
  State<_ProhibitionItem> createState() => _ProhibitionItemState();
}

class _ProhibitionItemState extends State<_ProhibitionItem> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.data['text'] as String? ?? '';
    final icon = widget.data['icon'] as String? ?? '⛔';
    final detail = widget.data['detail'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: detail != null
                ? () => setState(() => _showDetail = !_showDetail)
                : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (detail != null)
                    Icon(
                      _showDetail
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          if (_showDetail && detail != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        detail,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegacyProhibitions extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic> items;

  const _LegacyProhibitions({required this.data, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ...items.map((item) {
          final map = item as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.cardBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Text(map['icon'] as String? ?? '⛔',
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    map['text'] as String? ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Common Duas Tab
// ──────────────────────────────────────────────

class _DuasTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DuasTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data['items'] as List<dynamic>;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        final occasion = item['occasion'] as String? ?? '';
        final dua = item['dua'] as String? ?? '';
        final note = item['note'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  occasion,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                dua,
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  height: 1.8,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.justify,
              ),
              if (note != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// Sections Tab — reused for Preparation, Arkan/Wajibat, and Madinah Ziyarah.
// Renders a header (title + description) and a list of section cards.
// Each section card has a title (with optional emoji icon or ركن/واجب badge)
// and a bulleted list of items.
// ──────────────────────────────────────────────

class _SectionsTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SectionsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final sections = (data['sections'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Header banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    height: 1.7,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ...sections.map(
          (s) => _SectionCard(data: s as Map<String, dynamic>),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SectionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final icon = data['icon'] as String?;
    final type = data['type'] as String?;
    final items =
        (data['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];

    final accent = _accentForType(type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              if (icon != null && icon.isNotEmpty) ...[
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (type != null) _TypeBadge(type: type, color: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _accentForType(String? type) {
    switch (type) {
      case 'arkan':
        return const Color(0xFFC62828); // red — pillar
      case 'wajib':
        return const Color(0xFFE65100); // orange — obligation
      default:
        return AppColors.primary;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;

  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = type == 'arkan'
        ? 'ركن'
        : type == 'wajib'
            ? 'واجب'
            : 'سنة';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Nusuk entry banner — additive call-to-action that opens the interactive
// ritual tracker («نُسُكي»). Renders above the guide tabs; nothing in the
// guide itself is removed or changed.
// ──────────────────────────────────────────────

class _NusukEntryBanner extends StatelessWidget {
  const _NusukEntryBanner();

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: () => context.push('/nusuk'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: primary.withValues(alpha: 0.30)),
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.10),
                  primary.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.directions_walk_rounded,
                      color: primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ابدأ نُسُكي',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.secondary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'جديد',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تتبّع مناسكك خطوة بخطوة مع العدّادات والتقدّم',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
