import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/storage_service.dart';

/// State for the onboarding flow.
class OnboardingState {
  final int currentPage;
  final bool locationGranted;
  final bool notificationGranted;

  const OnboardingState({
    this.currentPage = 0,
    this.locationGranted = false,
    this.notificationGranted = false,
  });

  OnboardingState copyWith({
    int? currentPage,
    bool? locationGranted,
    bool? notificationGranted,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      locationGranted: locationGranted ?? this.locationGranted,
      notificationGranted: notificationGranted ?? this.notificationGranted,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final StorageService _storage;

  OnboardingNotifier(this._storage) : super(const OnboardingState());

  /// Total number of onboarding pages.
  static const int totalPages = 3;

  /// Move to the next page.
  void nextPage() {
    if (state.currentPage < totalPages - 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  /// Move to a specific page.
  void goToPage(int page) {
    if (page >= 0 && page < totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  /// Request location permission.
  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    final granted = status.isGranted;
    state = state.copyWith(locationGranted: granted);
    return granted;
  }

  /// Request notification permission (Android 13+).
  /// Also requests exact alarm permission (Android 12+) for scheduled notifications.
  Future<bool> requestNotificationPermission() async {
    // Android 13+ (API 33) requires explicit notification permission
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      final granted = status.isGranted;
      state = state.copyWith(notificationGranted: granted);

      // Also request exact alarm permission (Android 12+, API 31+)
      // This allows scheduling prayer time notifications at exact times
      if (granted) {
        await Permission.scheduleExactAlarm.request();
      }

      return granted;
    }
    // iOS or older Android — notifications work without explicit permission
    state = state.copyWith(notificationGranted: true);
    return true;
  }

  /// Mark onboarding as completed and persist the flag.
  Future<void> completeOnboarding() async {
    await _storage.putSetting('isFirstLaunch', false);
  }
}

/// Provider for the onboarding flow.
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(StorageService.instance);
});

/// Provider to check if this is the first launch.
final isFirstLaunchProvider = Provider<bool>((ref) {
  final storage = StorageService.instance;
  // Default to true if key doesn't exist (first install)
  return storage.getSetting<bool>('isFirstLaunch', defaultValue: true) ?? true;
});
