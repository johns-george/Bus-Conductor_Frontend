import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bootstrap state that decides what the very first screen should show.
@immutable
class AppBootstrap {
  const AppBootstrap({required this.hasSeenOnboarding});

  final bool hasSeenOnboarding;
}

class AppBootstrapController extends AsyncNotifier<AppBootstrap> {
  static const _kOnboardingSeen = 'bc.onboarding.seen';

  @override
  Future<AppBootstrap> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppBootstrap(
      hasSeenOnboarding: prefs.getBool(_kOnboardingSeen) ?? false,
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeen, true);
    state = const AsyncData(AppBootstrap(hasSeenOnboarding: true));
  }
}

final appBootstrapProvider =
    AsyncNotifierProvider<AppBootstrapController, AppBootstrap>(
  AppBootstrapController.new,
);
