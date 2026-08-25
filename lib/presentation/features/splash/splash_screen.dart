import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/app_bootstrap_provider.dart';
import '../../providers/repository_providers.dart';
import '../auth/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _resolveFirstRoute();
  }

  Future<void> _resolveFirstRoute() async {
    // Wait for bootstrap AsyncValue and a minimum splash duration in parallel
    // so the brand moment is always a tiny bit visible.
    await Future.wait([
      ref.read(appBootstrapProvider.future),
      Future<void>.delayed(const Duration(milliseconds: 1100)),
    ]);
    if (!mounted) return;
    final bootstrap = ref.read(appBootstrapProvider).requireValue;

    if (!bootstrap.hasSeenOnboarding) {
      context.go(AppRoutes.onboarding);
      return;
    }

    // Try to restore session from cookie (access/refresh token)
    final repo = ref.read(authRepositoryProvider);
    final session = await repo.currentSession;
    // Give the stream a moment to emit after restore
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final liveSession = ref.read(authSessionProvider).valueOrNull;

    if (liveSession != null) {
      // Session restored — route by role
      final role = liveSession.user.role?.toUpperCase();
      if (role == 'ADMIN') {
        context.go('/admin');
      } else if (role == 'CONDUCTOR') {
        context.go('/conductor');
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      // No valid session — go to login
      context.go(AppRoutes.authWelcome);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        children: [
          const _Aurora(),
          SafeArea(
            child: Padding(
              padding: AppSpacing.pageAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: _controller,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: const _BrandMark(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.3, 1, curve: Curves.easeOut),
                    ),
                    child: const Text(
                      'Bus Conductor',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.4, 1, curve: Curves.easeOut),
                    ),
                    child: Text(
                      'Your city, one tap away.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.5, 1, curve: Curves.easeOut),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(scheme.primary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Warming up routes...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                        ),
                      ],
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: AppRadii.rLg,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal, AppColors.tealStrong],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(AppIcons.bus, color: AppColors.midnightDeep, size: 42),
    );
  }
}

/// Subtle radial glow to give the splash background life without motion.
class _Aurora extends StatelessWidget {
  const _Aurora();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.8),
                  radius: 1.2,
                  colors: [
                    AppColors.teal.withValues(alpha: 0.18),
                    AppColors.midnight.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.9, 0.8),
                  radius: 0.9,
                  colors: [
                    AppColors.amber.withValues(alpha: 0.14),
                    AppColors.midnight.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
