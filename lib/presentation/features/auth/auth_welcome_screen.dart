import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';

/// First screen after onboarding when the user isn't signed in.
/// Offers Sign in / Create account / Continue as guest.
class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl2,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              const _BrandMark(accent: AppColors.teal),
              const SizedBox(height: AppSpacing.xl3),
              Text(
                'Welcome to\nBus Conductor',
                style: theme.textTheme.displaySmall?.copyWith(height: 1.1),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sign in to save routes, track tickets, and breeze through the daily commute.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Sign in',
                size: AppButtonSize.lg,
                onPressed: () => context.push(AppRoutes.login),
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'Create an account',
                size: AppButtonSize.lg,
                onPressed: () => context.push(AppRoutes.signup),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: GhostButton(
                  label: 'Continue as guest',
                  icon: AppIcons.chevronRight,
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  'By continuing you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: AppRadii.rLg,
            gradient: LinearGradient(
              colors: [accent, AppColors.tealStrong],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(AppIcons.bus, color: Colors.white, size: 26),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          'Bus Conductor',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
