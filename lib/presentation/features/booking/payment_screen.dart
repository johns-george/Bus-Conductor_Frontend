import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/wallet.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import 'booking_controller.dart';
import 'widgets/booking_stepper.dart';

/// Step 3 of the booking flow — method picker, fare breakdown, and Pay CTA.
class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  static const _methods = [
    _MethodOption(
      id: 'pm_upi',
      type: PaymentMethodType.upi,
      title: 'UPI',
      subtitle: 'alex@okhdfc',
      icon: Icons.qr_code_2_rounded,
    ),
    _MethodOption(
      id: 'pm_card',
      type: PaymentMethodType.card,
      title: 'HDFC Credit Card',
      subtitle: 'Visa \u2022\u2022\u2022\u2022 4421',
      icon: Icons.credit_card_rounded,
    ),
    _MethodOption(
      id: 'pm_netbanking',
      type: PaymentMethodType.netbanking,
      title: 'Net banking',
      subtitle: 'All major banks',
      icon: Icons.account_balance_rounded,
    ),
    _MethodOption(
      id: 'pm_wallet',
      type: PaymentMethodType.wallet,
      title: 'Bus Conductor Wallet',
      subtitle: 'Pay instantly from balance',
      icon: AppIcons.wallet,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final draft = ref.watch(bookingControllerProvider);
    final walletAsync = ref.watch(walletProvider);

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: ErrorStateView(
            title: 'No active booking',
            message: 'Please start a booking from a route.',
            onRetry: () => context.pop(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const BookingStepper(current: BookingStage.payment),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _FareBreakdown(draft: draft),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Payment method',
                      style: theme.textTheme.titleMedium,),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choose how you want to pay.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final method in _methods)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _MethodTile(
                        method: method,
                        selected: draft.paymentMethodId == method.id,
                        walletAsync: method.type == PaymentMethodType.wallet
                            ? walletAsync
                            : null,
                        onTap: () => ref
                            .read(bookingControllerProvider.notifier)
                            .setPaymentMethod(method.id),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  _SecurityNote(),
                ],
              ),
            ),
            _PayFooter(draft: draft),
          ],
        ),
      ),
    );
  }
}

class _FareBreakdown extends StatelessWidget {
  const _FareBreakdown({required this.draft});
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
        children: [
          _row(theme, palette, 'Route', draft.route.name),
          const SizedBox(height: AppSpacing.xs),
          _row(theme, palette, 'Leg',
              '${draft.from.name} \u2192 ${draft.to.name}',),
          const SizedBox(height: AppSpacing.xs),
          _row(theme, palette, 'Ticket type', 'Route-based ticket'),
          Divider(
            height: AppSpacing.lg,
            color: palette.border,
          ),
          _row(theme, palette, 'Subtotal', Money.format(draft.fare)),
          const SizedBox(height: AppSpacing.xs),
          _row(theme, palette, 'Taxes & fees', Money.format(draft.taxes)),
          Divider(
            height: AppSpacing.lg,
            color: palette.border,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total payable', style: theme.textTheme.titleMedium),
              Text(
                Money.format(draft.total),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.tealStrong,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(
      ThemeData theme, AppSurfaces palette, String label, String value,) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MethodOption {
  const _MethodOption({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String id;
  final PaymentMethodType type;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
    this.walletAsync,
  });
  final _MethodOption method;
  final bool selected;
  final VoidCallback onTap;
  final AsyncValue<Wallet?>? walletAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.tealSoft : palette.surface,
            borderRadius: AppRadii.rMd,
            border: Border.all(
              color: selected ? AppColors.teal : palette.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : palette.surfaceMuted,
                  borderRadius: AppRadii.rSm,
                ),
                alignment: Alignment.center,
                child: Icon(method.icon,
                    color: AppColors.tealStrong, size: 20,),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.title,
                        style: theme.textTheme.titleSmall,),
                    const SizedBox(height: 2),
                    _subtitle(theme, palette),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? AppColors.teal : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.tealStrong : palette.borderStrong,
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14,)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subtitle(ThemeData theme, AppSurfaces palette) {
    if (method.type != PaymentMethodType.wallet || walletAsync == null) {
      return Text(
        method.subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: palette.textMuted,
        ),
      );
    }
    return walletAsync!.when(
      loading: () => const AppShimmer(
        child: SkeletonBlock(height: 14, radius: AppRadii.pill),
      ),
      error: (_, __) => Text(
        method.subtitle,
        style:
            theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
      ),
      data: (wallet) {
        final balance = wallet?.balance ?? 0;
        return Text(
          'Balance ${Money.format(balance)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textMuted,
          ),
        );
      },
    );
  }
}

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadii.rMd,
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined,
              color: palette.textSecondary, size: 18,),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Payments are encrypted end-to-end. Mock gateway in this build — '
              'no real charge will be made.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayFooter extends ConsumerWidget {
  const _PayFooter({required this.draft});
  final BookingDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (draft.errorMessage != null) ...[
            Text(
              draft.errorMessage!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          PrimaryButton(
            label: 'Pay ${Money.format(draft.total)}',
            icon: Icons.lock_rounded,
            size: AppButtonSize.lg,
            loading: draft.isProcessing,
            onPressed: draft.paymentMethodId == null || draft.isProcessing
                ? null
                : () async {
                    final ok = await ref
                        .read(bookingControllerProvider.notifier)
                        .pay();
                    if (ok && context.mounted) {
                      context.pushReplacement('/booking/success');
                    }
                  },
          ),
        ],
      ),
    );
  }
}
