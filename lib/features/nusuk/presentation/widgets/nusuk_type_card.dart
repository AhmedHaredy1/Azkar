import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/nusuk_type.dart';

/// Selectable card for one [NusukType] on the hub. When [disabled] (e.g. a Hajj
/// already completed this Hijri year) it dims and shows a lock + [disabledNote].
class NusukTypeCard extends StatelessWidget {
  final NusukType type;
  final VoidCallback onTap;
  final bool disabled;
  final String? disabledNote;

  const NusukTypeCard({
    super.key,
    required this.type,
    required this.onTap,
    this.disabled = false,
    this.disabledNote,
  });

  IconData get _icon {
    switch (type) {
      case NusukType.umrah:
        return Icons.brightness_3_rounded;
      case NusukType.tamattu:
        return Icons.all_inclusive_rounded;
      case NusukType.qiran:
        return Icons.link_rounded;
      case NusukType.ifrad:
        return Icons.flag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final showNote = disabled && disabledNote != null;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(_icon, color: primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              type.arabicName,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _Badge(label: type.badge, color: primary),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        showNote ? disabledNote! : type.subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          height: 1.5,
                          color: showNote
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  disabled
                      ? Icons.lock_outline_rounded
                      : Icons.chevron_left_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
