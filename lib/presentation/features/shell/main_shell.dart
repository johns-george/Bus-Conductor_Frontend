import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';

/// Bottom-nav shell that hosts Home, Tickets, Scan, Wallet, Profile.
/// Uses a `StatefulNavigationShell` so each tab keeps its stack state across
/// tab switches.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _items = <_ShellTab>[
    _ShellTab(icon: AppIcons.home, label: 'Home'),
    _ShellTab(icon: AppIcons.ticket, label: 'Tickets'),
    _ShellTab(icon: AppIcons.wallet, label: 'Wallet'),
    _ShellTab(icon: AppIcons.profile, label: 'Profile'),
  ];

  void _goTo(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Scaffold(
      backgroundColor: palette.background,
      body: navigationShell,
      bottomNavigationBar: AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadii.rXl,
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    _BottomTab(
                      tab: _items[i],
                      isActive: navigationShell.currentIndex == i,
                      onTap: () => _goTo(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.icon,
    required this.label,
    this.prominent = false,
  });
  final IconData icon;
  final String label;
  final bool prominent;
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final _ShellTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    if (tab.prominent) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.teal, AppColors.tealStrong],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(tab.icon, color: Colors.white, size: 26),
        ),
      );
    }
    final color = isActive ? AppColors.teal : palette.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1,
                duration: AppDurations.fast,
                child: Icon(tab.icon, color: color, size: 22),
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder for tabs whose full screens land in Phase 3. Keeps the shell
/// navigable today.
class ShellPlaceholder extends StatelessWidget {
  const ShellPlaceholder({super.key, required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: AppRadii.rLg,
                ),
                child: Icon(icon, size: 34, color: AppColors.tealStrong),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '$title is arriving in Phase 3',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Booking, ticketing, wallet, and profile land in the next pass.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton.icon(
                onPressed: () =>
                    GoRouter.of(context).go(AppRoutes.home),
                icon: const Icon(AppIcons.home, size: 18),
                label: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
