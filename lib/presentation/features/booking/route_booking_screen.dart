import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../widgets/buttons/primary_button.dart';
import '../booking/booking_controller.dart';
import '../booking/widgets/booking_stepper.dart';

/// Route-based booking entry point - allows booking directly on a route
/// without selecting specific buses or seats
class RouteBookingScreen extends ConsumerWidget {
  const RouteBookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final draft = ref.watch(bookingControllerProvider);

    if (draft == null) {
      return _MissingDraft(onDismiss: () => context.pop());
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Book Ticket'),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const BookingStepper(current: BookingStage.passenger),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RouteSummary(draft: draft),
                    const SizedBox(height: AppSpacing.lg),
                    _FareSummary(draft: draft),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Continue to Passenger Details',
                      icon: AppIcons.chevronRight,
                      size: AppButtonSize.lg,
                      onPressed: () {
                        context.push('/booking/passenger');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.draft});
  final BookingDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: AppRadii.rSm,
                ),
                alignment: Alignment.center,
                child: const Icon(AppIcons.bus,
                    color: AppColors.tealStrong, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.route.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Route-based ticket',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _RouteLeg(
            from: draft.from.name,
            to: draft.to.name,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _RouteLeg extends StatelessWidget {
  const _RouteLeg({
    required this.from,
    required this.to,
    this.isLast = false,
  });

  final String from;
  final String to;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: palette.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  to,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FareSummary extends StatelessWidget {
  const _FareSummary({required this.draft});
  final BookingDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Details',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          _FareRow(
            label: 'Base Fare',
            value: Money.format(draft.fare),
            theme: theme,
            palette: palette,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FareRow(
            label: 'Taxes & Fees',
            value: Money.format(draft.taxes),
            theme: theme,
            palette: palette,
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: palette.border),
          const SizedBox(height: AppSpacing.sm),
          _FareRow(
            label: 'Total Amount',
            value: Money.format(draft.total),
            theme: theme,
            palette: palette,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.palette,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final AppSurfaces palette;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: isTotal ? null : palette.textMuted,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? AppColors.tealStrong : null,
            fontSize: isTotal ? 16 : null,
          ),
        ),
      ],
    );
  }
}

class _MissingDraft extends StatelessWidget {
  const _MissingDraft({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: onDismiss,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                AppIcons.bus,
                size: 64,
                color: AppColors.n300,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No active booking',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Start by selecting a route to book your ticket.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.n500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Go Back',
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
