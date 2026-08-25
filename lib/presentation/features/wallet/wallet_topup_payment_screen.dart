import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/payment.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/buttons/primary_button.dart';
import '../auth/auth_controller.dart';
import 'wallet_screen.dart';

/// Payment screen for wallet top-up — loads user's saved payment methods
/// and lets them pick one or add a new one.
class WalletTopupPaymentScreen extends ConsumerStatefulWidget {
  const WalletTopupPaymentScreen({super.key, required this.amount});
  final num amount;

  @override
  ConsumerState<WalletTopupPaymentScreen> createState() =>
      _WalletTopupPaymentScreenState();
}

class _WalletTopupPaymentScreenState
    extends ConsumerState<WalletTopupPaymentScreen> {
  String? _selectedMethodId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Add money to wallet'),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Amount card
                  _AmountCard(amount: widget.amount),
                  const SizedBox(height: AppSpacing.xl),

                  // Payment methods header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment method', style: theme.textTheme.titleMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Choose how you want to add money.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _addNewMethod(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add new'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Saved methods or empty state
                  if (session != null)
                    _SavedMethodsList(
                      userId: session.user.id,
                      selectedId: _selectedMethodId,
                      onSelect: (id) => setState(() => _selectedMethodId = id),
                    ),

                  const SizedBox(height: AppSpacing.xl),
                  _SecurityNote(),
                ],
              ),
            ),

            // Pay button footer
            _PayFooter(
              amount: widget.amount,
              hasSelection: _selectedMethodId != null,
              isProcessing: _isProcessing,
              onPressed: _processPayment,
            ),
          ],
        ),
      ),
    );
  }

  void _addNewMethod(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickAddMethodSheet(),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedMethodId == null || _isProcessing) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _isProcessing = true);

    try {
      // Find the selected method to get its details
      final methods = await ref
          .read(paymentMethodRepositoryProvider)
          .listByUser(session.user.id);
      final selected = methods.firstWhere(
        (m) => m.id == _selectedMethodId,
        orElse: () => methods.first,
      );

      await ref.read(walletRepositoryProvider).topUpViaPayment(
            userId: session.user.id,
            amount: widget.amount,
            methodType: selected.type.name.toUpperCase(),
            methodId: selected.id,
            methodLabel: selected.label,
          );

      // Refresh wallet and transactions
      ref.invalidate(walletTabProvider(session.user.id));
      ref.invalidate(walletTransactionsProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${Money.format(widget.amount)} to wallet via ${selected.label}'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _SavedMethodsList extends ConsumerWidget {
  const _SavedMethodsList({
    required this.userId,
    required this.selectedId,
    required this.onSelect,
  });
  final String userId;
  final String? selectedId;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_paymentMethodsProvider(userId));
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

    return async.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Text('Failed to load methods: $e',
            style: theme.textTheme.bodySmall),
      ),
      data: (methods) {
        if (methods.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadii.rMd,
            ),
            child: Column(
              children: [
                Icon(Icons.credit_card_rounded, size: 32, color: palette.textMuted),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No saved payment methods',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "Add new" to add UPI, card, or net banking.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return Column(
          children: methods.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SavedMethodTile(
              method: m,
              selected: selectedId == m.id,
              onTap: () => onSelect(m.id),
            ),
          )).toList(),
        );
      },
    );
  }
}

class _SavedMethodTile extends StatelessWidget {
  const _SavedMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

    final IconData typeIcon = switch (method.type) {
      PaymentMethodType.upi => Icons.qr_code_2_rounded,
      PaymentMethodType.card => Icons.credit_card_rounded,
      PaymentMethodType.netbanking => Icons.account_balance_rounded,
      PaymentMethodType.wallet => AppIcons.wallet,
    };

    final Color tone = switch (method.type) {
      PaymentMethodType.upi => AppColors.tealStrong,
      PaymentMethodType.card => AppColors.info,
      PaymentMethodType.netbanking => AppColors.amberStrong,
      PaymentMethodType.wallet => AppColors.success,
    };

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
                  color: selected ? Colors.white : tone.withValues(alpha: 0.12),
                  borderRadius: AppRadii.rSm,
                ),
                alignment: Alignment.center,
                child: Icon(typeIcon, color: tone, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(method.label, style: theme.textTheme.titleSmall),
                        if (method.isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.tealStrong,
                              borderRadius: AppRadii.rSm,
                            ),
                            child: Text(
                              'DEFAULT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.subtitle ?? method.type.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick-add sheet shown from the top-up screen
class _QuickAddMethodSheet extends ConsumerStatefulWidget {
  const _QuickAddMethodSheet();

  @override
  ConsumerState<_QuickAddMethodSheet> createState() => _QuickAddMethodSheetState();
}

class _QuickAddMethodSheetState extends ConsumerState<_QuickAddMethodSheet> {
  PaymentMethodType _type = PaymentMethodType.upi;
  final _labelCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(authSessionProvider).valueOrNull;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick add method', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),

            // Type chips
            Row(
              children: PaymentMethodType.values
                  .where((t) => t != PaymentMethodType.wallet)
                  .map((t) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _type = t;
                            _labelCtrl.clear();
                            _detailCtrl.clear();
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: _type == t ? AppColors.tealSoft : Colors.transparent,
                              borderRadius: AppRadii.rSm,
                              border: Border.all(
                                color: _type == t ? AppColors.teal : Theme.of(context).dividerColor,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(t.label),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                labelText: _type == PaymentMethodType.upi ? 'UPI name' : 'Label',
                hintText: _type == PaymentMethodType.upi ? 'Google Pay' : 'HDFC Card',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _detailCtrl,
              decoration: InputDecoration(
                labelText: _type == PaymentMethodType.upi ? 'UPI ID' : 'Last 4 digits',
                hintText: _type == PaymentMethodType.upi ? 'name@okaxis' : '4421',
              ),
              keyboardType: _type == PaymentMethodType.upi
                  ? TextInputType.emailAddress
                  : TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(
              label: _saving ? 'Adding...' : 'Add method',
              icon: Icons.add_rounded,
              loading: _saving,
              onPressed: (_saving || session == null)
                  ? null
                  : () async {
                      final label = _labelCtrl.text.trim();
                      if (label.isEmpty) return;

                      setState(() => _saving = true);
                      try {
                        final subtitle = _type == PaymentMethodType.upi
                            ? _detailCtrl.text.trim()
                            : '•••• ${_detailCtrl.text.trim()}';
                        await ref.read(paymentMethodRepositoryProvider).create(
                              userId: session.user.id,
                              type: _type,
                              label: label,
                              subtitle: subtitle,
                              upiId: _type == PaymentMethodType.upi
                                  ? _detailCtrl.text.trim()
                                  : null,
                              lastFour: _type == PaymentMethodType.card
                                  ? _detailCtrl.text.trim()
                                  : null,
                            );
                        ref.invalidate(_paymentMethodsProvider(session.user.id));
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amount});
  final num amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadii.rLg,
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.midnightSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top-up amount',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            Money.format(amount),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
          Icon(Icons.verified_user_outlined, color: palette.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Payments are encrypted end-to-end. Mock gateway — no real charge will be made.',
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

class _PayFooter extends StatelessWidget {
  const _PayFooter({
    required this.amount,
    required this.hasSelection,
    required this.isProcessing,
    required this.onPressed,
  });

  final num amount;
  final bool hasSelection;
  final bool isProcessing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
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
      child: PrimaryButton(
        label: 'Pay ${Money.format(amount)}',
        icon: Icons.lock_rounded,
        size: AppButtonSize.lg,
        loading: isProcessing,
        onPressed: !hasSelection || isProcessing ? null : onPressed,
      ),
    );
  }
}

// Shared provider for fetching payment methods
final _paymentMethodsProvider = FutureProvider.autoDispose
    .family<List<PaymentMethod>, String>((ref, userId) async {
  return ref.watch(paymentMethodRepositoryProvider).listByUser(userId);
});
