import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/tokens.dart';
import '../../settings/presentation/providers/settings_provider.dart';
import 'providers/notification_provider.dart';

/// Diagnostic screen for verifying prayer-notification health on-device.
/// Shows every permission gate + lists currently scheduled notifications
/// so the user can confirm alerts are actually armed.
class NotificationStatusScreen extends ConsumerStatefulWidget {
  const NotificationStatusScreen({super.key});

  @override
  ConsumerState<NotificationStatusScreen> createState() =>
      _NotificationStatusScreenState();
}

class _NotificationStatusScreenState
    extends ConsumerState<NotificationStatusScreen> {
  NotificationDiagnostics? _diagnostics;
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      // Cap the probe at 8 seconds so a misbehaving platform call can't leave
      // the UI stuck — the user will see a readable error instead of a spinner.
      final diag = await ref
          .read(notificationServiceProvider)
          .getDiagnostics()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _diagnostics = diag;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    try {
      final manager = ref.read(notificationManagerProvider);
      await manager.requestPermissions();
      _snack('تم طلب الأذونات — تحقق من الحالة أدناه');
    } catch (e) {
      _snack('تعذّر طلب الأذونات: $e', error: true);
    } finally {
      await _refresh();
    }
  }

  Future<void> _rescheduleNow() async {
    try {
      final manager = ref.read(notificationManagerProvider);
      final settings = ref.read(settingsProvider);
      if (settings.latitude == null || settings.longitude == null) {
        _snack('الرجاء تحديد الموقع من الإعدادات أولاً', error: true);
        return;
      }
      await manager.rescheduleAll(settings);
      _snack('تمت إعادة جدولة التنبيهات');
    } catch (e) {
      _snack('فشل إعادة الجدولة: $e', error: true);
    } finally {
      await _refresh();
    }
  }

  Future<void> _forceStorageRecovery() async {
    try {
      final cleared =
          await ref.read(notificationServiceProvider).forceStorageRecovery();
      _snack(cleared
          ? 'تم مسح التخزين التالف — جاري إعادة الجدولة'
          : 'لم يتم العثور على تخزين تالف');
      if (cleared) {
        final manager = ref.read(notificationManagerProvider);
        final settings = ref.read(settingsProvider);
        if (settings.latitude != null && settings.longitude != null) {
          await manager.rescheduleAll(settings);
        }
      }
    } catch (e) {
      _snack('فشل مسح التخزين: $e', error: true);
    } finally {
      await _refresh();
    }
  }

  Future<void> _fireTestNotification() async {
    // Schedule a one-off notification 10 seconds from now. If this doesn't
    // appear, the problem is with notification delivery itself (permission,
    // channel, battery optimization) — not with prayer-time calculation.
    try {
      final fireAt = DateTime.now().add(const Duration(seconds: 10));
      await ref.read(notificationServiceProvider).scheduleNotification(
        id: 999,
        channelId: NotificationService.prayerChannelId,
        title: 'اختبار التنبيهات',
        body: 'إذا ظهر هذا التنبيه فالنظام يعمل بشكل صحيح',
        scheduledTime: fireAt,
        payload: 'test',
      );
      _snack('تم جدولة تنبيه اختباري — سيظهر خلال ١٠ ثواني');
    } catch (e) {
      _snack('فشل جدولة التنبيه الاختباري: $e', error: true);
    } finally {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final diag = _diagnostics;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'تشخيص التنبيهات',
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (_loading && diag == null && _loadError == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_loadError != null) _errorBanner(_loadError!),
            if (diag != null) ...[
              if (diag.errors.isNotEmpty) _probeErrorsBanner(diag.errors),
              _healthBanner(diag),
              const SizedBox(height: AppSpacing.lg),
              _statusTile(
                label: 'إذن التنبيهات',
                subtitle: 'POST_NOTIFICATIONS (Android 13+)',
                ok: diag.notificationPermissionGranted,
              ),
              _statusTile(
                label: 'إذن المنبهات الدقيقة',
                subtitle: 'SCHEDULE_EXACT_ALARM (Android 12+)',
                ok: diag.exactAlarmsAllowed,
              ),
              _statusTile(
                label: 'استثناء من توفير البطارية',
                subtitle:
                    'مطلوب على شاومي/هواوي/أوبو/ون بلس — بدونه تُحذف المنبهات',
                ok: diag.batteryOptimizationWhitelisted,
              ),
              const SizedBox(height: AppSpacing.lg),
              _pendingSection(diag),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _requestAllPermissions,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('طلب جميع الأذونات'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _rescheduleNow,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة جدولة جميع التنبيهات'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _fireTestNotification,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('تنبيه اختباري بعد ١٠ ثواني'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: _forceStorageRecovery,
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('إصلاح تخزين التنبيهات (للأخطاء)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _snack('تم نسخ الخطأ إلى الحافظة');
  }

  Future<void> _shareError(String text) async {
    await Share.share(text, subject: 'Azkar - Notification error');
  }

  Widget _copyShareRow(String text) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => _copyToClipboard(text),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('نسخ'),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => _shareError(text),
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text('مشاركة'),
        ),
      ],
    );
  }

  Widget _errorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'تعذّر تحميل التشخيص',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Selectable so the user can long-press to select text manually too.
          SelectableText(
            error,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('إعادة المحاولة'),
              ),
              TextButton.icon(
                onPressed: () => _copyToClipboard(error),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('نسخ الخطأ'),
              ),
              TextButton.icon(
                onPressed: () => _shareError(error),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('مشاركة'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _probeErrorsBanner(List<String> errors) {
    final fullText = errors.join('\n\n');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'تعذّر قراءة بعض الفحوصات',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Whole block selectable so the user can copy the full stack trace.
          SelectableText(
            errors.map((e) => '• $e').join('\n'),
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _copyShareRow(fullText),
        ],
      ),
    );
  }

  Widget _healthBanner(NotificationDiagnostics diag) {
    final ok = diag.allHealthy;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: (ok ? AppColors.primary : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (ok ? AppColors.primary : Colors.orange)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: ok ? AppColors.primary : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              ok
                  ? 'جميع التنبيهات جاهزة للعمل بشكل صحيح'
                  : 'بعض الأذونات غير مكتملة — التنبيهات قد لا تعمل',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTile({
    required String label,
    required String subtitle,
    required bool ok,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green : Colors.red,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingSection(NotificationDiagnostics diag) {
    final pending = diag.pendingNotifications;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'التنبيهات المجدولة (${pending.length})',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (pending.isEmpty)
            Text(
              'لا توجد تنبيهات مجدولة — اضغط "إعادة جدولة" أدناه',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...pending.take(10).map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• [${p.id}] ${p.title ?? ''} — ${p.body ?? ''}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )),
          if (pending.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... و ${pending.length - 10} أخرى',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
