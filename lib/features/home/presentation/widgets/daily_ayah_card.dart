import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/arabic_number_utils.dart';
import '../../../../core/widgets/ornaments.dart';
import '../../../quran/presentation/providers/quran_audio_provider.dart';
import '../providers/home_provider.dart';

/// Minimal ayah card — white surface, hairline border, gold star outline as
/// the only ornament. The ayah uses the Quranic typography, a hairline
/// divides it from the small action row (استمع / شارك / نسخ).
class DailyAyahCard extends ConsumerStatefulWidget {
  const DailyAyahCard({super.key});

  @override
  ConsumerState<DailyAyahCard> createState() => _DailyAyahCardState();
}

class _DailyAyahCardState extends ConsumerState<DailyAyahCard> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerSub;
  bool _isLoading = false;
  bool _isPlaying = false;

  @override
  void dispose() {
    _playerSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  /// Lazily creates the player and attaches its state listener exactly once
  /// for the lifetime of the card — re-listening on every play toggle leaks
  /// subscriptions that all fire setState.
  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _playerSub = player.playerStateStream.listen((s) {
      if (!mounted) return;
      if (s.processingState == ProcessingState.completed) {
        setState(() => _isPlaying = false);
      }
    });
    _player = player;
    return player;
  }

  Future<void> _toggleListen(DailyAyahState ayah) async {
    if (_isPlaying) {
      await _player?.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final player = _ensurePlayer();
      final globalAyah =
          getGlobalAyahNumber(ayah.surahNumber, ayah.ayahNumber);
      // Default to Alafasy 128k — matches the Quran reader's default reciter.
      final url =
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyah.mp3';

      await player.setUrl(url);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = true;
      });
      await player.play();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تشغيل الآية. تحقق من الاتصال بالإنترنت.')),
      );
    }
  }

  String _shareText(DailyAyahState ayah) {
    final ayahNum = ArabicNumberUtils.toEasternArabic(ayah.ayahNumber);
    return '${ayah.ayahText}\n\n﴿${ayah.surahName} - آية $ayahNum﴾\n\n— من تطبيق رفيق المسلم';
  }

  Future<void> _share(DailyAyahState ayah) async {
    await Share.share(_shareText(ayah));
  }

  Future<void> _copy(DailyAyahState ayah) async {
    await Clipboard.setData(ClipboardData(text: _shareText(ayah)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الآية')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ayahAsync = ref.watch(dailyAyahProvider);

    return ayahAsync.when(
      data: (ayah) {
        if (!ayah.hasData) return const SizedBox.shrink();
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(surahName: ayah.surahName, ayahNumber: ayah.ayahNumber),
              const SizedBox(height: AppSpacing.md),
              Text(
                ayah.ayahText,
                textAlign: TextAlign.right,
                style: GoogleFonts.notoNaskhArabic(
                  fontSize: 22,
                  height: 1.9,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const HairDivider(),
              const SizedBox(height: AppSpacing.md),
              _actions(ayah),
            ],
          ),
        );
      },
      loading: () => _Card(
        child: const SizedBox(
          height: 140,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.ink3,
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _header({required String surahName, required int ayahNumber}) {
    return Row(
      children: [
        StarOutline(
          size: 11,
          color: AppColors.secondary,
          strokeWidth: 1.2,
        ),
        const SizedBox(width: 8),
        Text(
          'آية اليوم',
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
            color: AppColors.ink3,
          ),
        ),
        const Spacer(),
        Text(
          '$surahName · ${ArabicNumberUtils.toEasternArabic(ayahNumber)}',
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: AppColors.ink3,
          ),
        ),
      ],
    );
  }

  Widget _actions(DailyAyahState ayah) {
    final listenIcon = _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded;
    final listenLabel = _isPlaying ? 'إيقاف' : 'استمع';
    return Row(
      children: [
        _ActionItem(
          icon: listenIcon,
          label: listenLabel,
          loading: _isLoading,
          onTap: () => _toggleListen(ayah),
        ),
        const SizedBox(width: 18),
        _ActionItem(
          icon: Icons.share_outlined,
          label: 'شارك',
          onTap: () => _share(ayah),
        ),
        const SizedBox(width: 18),
        _ActionItem(
          icon: Icons.content_copy_rounded,
          label: 'نسخ',
          onTap: () => _copy(ayah),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg + 2,
        AppSpacing.lg + 2,
        AppSpacing.lg + 2,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      child: child,
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: AppColors.ink2,
                ),
              )
            else
              Icon(icon, size: 14, color: AppColors.ink2),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
