import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadii.rLg,
                  border: Border.all(color: palette.border),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No notifications yet',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Booking confirmations, trip reminders, and offers will appear here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
