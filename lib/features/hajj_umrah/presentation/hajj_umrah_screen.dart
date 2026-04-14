import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

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
      length: 5,
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
              Tab(text: 'العمرة'),
              Tab(text: 'الحج'),
              Tab(text: 'أنواع الحج'),
              Tab(text: 'المحظورات'),
              Tab(text: 'الأدعية'),
            ],
          ),
        ),
        body: dataAsync.when(
          data: (data) => TabBarView(
            children: [
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
              _ProhibitionsTab(
                data: data['prohibitions'] as Map<String, dynamic>,
              ),
              _DuasTab(
                data: data['commonDuas'] as Map<String, dynamic>,
              ),
            ],
          ),
          loading: () => const Center(
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
      padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Step number badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 12),
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
              padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 8),
                          ...widget.duas.map((dua) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              const Icon(Icons.mosque, color: AppColors.primary, size: 36),
              const SizedBox(height: 8),
              Text(
                data['title'] as String? ?? '',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
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
        const SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                            const SizedBox(width: 8),
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
                        const SizedBox(height: 4),
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
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 16),
                  Text(
                    'الخطوات:',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            const SizedBox(width: 8),
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
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 36),
              const SizedBox(height: 8),
              Text(
                data['title'] as String? ?? '',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              if (data['description'] != null) ...[
                const SizedBox(height: 4),
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
        const SizedBox(height: 16),

        // Categories
        ...categories.map((cat) {
          final catMap = cat as Map<String, dynamic>;
          final catTitle = catMap['title'] as String? ?? '';
          final items = catMap['items'] as List<dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
              const SizedBox(height: 8),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: detail != null
                ? () => setState(() => _showDetail = !_showDetail)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
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
      padding: const EdgeInsets.all(16),
      children: [
        ...items.map((item) {
          final map = item as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        final occasion = item['occasion'] as String? ?? '';
        final dua = item['dua'] as String? ?? '';
        final note = item['note'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 12),
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
