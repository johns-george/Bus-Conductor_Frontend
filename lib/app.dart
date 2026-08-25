import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_events.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/features/auth/auth_controller.dart';
import 'presentation/providers/theme_provider.dart';

class BusConductorApp extends ConsumerStatefulWidget {
  const BusConductorApp({super.key});

  @override
  ConsumerState<BusConductorApp> createState() => _BusConductorAppState();
}

class _BusConductorAppState extends ConsumerState<BusConductorApp> {
  StreamSubscription<void>? _authSub;

  @override
  void initState() {
    super.initState();
    // Listen for auth failure events (401 after refresh fail)
    _authSub = AuthEvents.onAuthFailed.listen((_) {
      if (!mounted) return;
      // Clear session and redirect to login
      ref.read(authControllerProvider.notifier).logout();
      context.go('/auth');
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'Bus Conductor',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: brightness == Brightness.dark
              ? SystemUiOverlayStyle.light.copyWith(
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness: Brightness.light,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.2,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
