import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/payment.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/empty_state.dart';
import '../auth/auth_controller.dart';

/// Screen to manage saved payment methods (add, delete, set default).
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Payment methods'),
        actions: [
          if (session != null)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add method',
              onPressed: () => _showAddMethodSheet(context, ref, session.user.id),
            ),
        ],
      ),
      body: session == null
          ? Center(
              child: EmptyState(
                icon: Icons.credit_card_off_rounded,
                title: 'Not logged in',
                message: 'Log in to manage payment methods.',
              ),
            )
          : _MethodsList(userId: session.user.id),
    );
  }

  void _showAddMethodSheet(BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMethodSheet(userId: userId),
    );
  }
}

class _MethodsList extends ConsumerWidget {
  const _MethodsList({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_paymentMethodsProvider(userId));
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: AppSpacing.pageAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load payment methods',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('$e', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref.invalidate(_paymentMethodsProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (methods) {
        if (methods.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            children: [
              EmptyState(
                icon: Icons.credit_card_rounded,
                title: 'No payment methods',
                message: 'Add a UPI, card, or net banking method to pay faster.',
              ),
            ],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: methods.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (ctx, i) => _MethodCard(
            method: methods[i],
            userId: userId,
          ),
        );
      },
    );
  }
}

class _MethodCard extends ConsumerWidget {
  const _MethodCard({required this.method, required this.userId});
  final PaymentMethod method;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: method.isDefault ? AppColors.tealSoft : palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(
          color: method.isDefault ? AppColors.teal : palette.border,
          width: method.isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: AppRadii.rSm,
            ),
            alignment: Alignment.center,
            child: Icon(typeIcon, color: tone, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        method.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (method.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tealStrong,
                          borderRadius: AppRadii.rSm,
                        ),
                        child: Text(
                          'DEFAULT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: palette.textMuted, size: 20),
            onSelected: (value) => _handleAction(context, ref, value),
            itemBuilder: (_) => [
              if (!method.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(Icons.star_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Set as default'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(paymentMethodRepositoryProvider);
    final methodId = int.tryParse(method.id);
    if (methodId == null) return;

    if (action == 'default') {
      await repo.setDefault(userId: userId, methodId: methodId);
      ref.invalidate(_paymentMethodsProvider(userId));
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove payment method?'),
          content: Text('Remove "${method.label}" from your saved methods?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await repo.delete(userId: userId, methodId: methodId);
        ref.invalidate(_paymentMethodsProvider(userId));
      }
    }
  }
}

class _AddMethodSheet extends ConsumerStatefulWidget {
  const _AddMethodSheet({required this.userId});
  final String userId;

  @override
  ConsumerState<_AddMethodSheet> createState() => _AddMethodSheetState();
}

class _AddMethodSheetState extends ConsumerState<_AddMethodSheet> {
  PaymentMethodType _type = PaymentMethodType.upi;
  final _labelCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _upiIdCtrl = TextEditingController();
  bool _isDefault = false;
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _subtitleCtrl.dispose();
    _upiIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

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
            Text('Add payment method', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),

            // Type selector
            Text('Type', style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: PaymentMethodType.values
                  .where((t) => t != PaymentMethodType.wallet)
                  .map((t) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _type = t;
                            _labelCtrl.clear();
                            _subtitleCtrl.clear();
                            _upiIdCtrl.clear();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: _type == t ? AppColors.tealSoft : palette.surfaceMuted,
                              borderRadius: AppRadii.rSm,
                              border: Border.all(
                                color: _type == t ? AppColors.teal : palette.border,
                                width: _type == t ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              t.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _type == t ? AppColors.tealStrong : palette.textSecondary,
                                fontWeight: _type == t ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Label
            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                labelText: _type == PaymentMethodType.upi
                    ? 'UPI name'
                    : _type == PaymentMethodType.card
                        ? 'Card name'
                        : 'Bank name',
                hintText: _type == PaymentMethodType.upi
                    ? 'e.g. Google Pay'
                    : _type == PaymentMethodType.card
                        ? 'e.g. HDFC Credit Card'
                        : 'e.g. SBI Net Banking',
                prefixIcon: Icon(
                  _type == PaymentMethodType.upi
                      ? Icons.qr_code_2_rounded
                      : _type == PaymentMethodType.card
                          ? Icons.credit_card_rounded
                          : Icons.account_balance_rounded,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),

            // Subtitle / identifier
            if (_type == PaymentMethodType.upi) ...[
              TextField(
                controller: _upiIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'e.g. name@okaxis',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ] else if (_type == PaymentMethodType.card) ...[
              TextField(
                controller: _subtitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last 4 digits',
                  hintText: 'e.g. 4421',
                  prefixIcon: Icon(Icons.pin_rounded),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
            ] else ...[
              TextField(
                controller: _subtitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account type',
                  hintText: 'e.g. Savings',
                  prefixIcon: Icon(Icons.account_balance_rounded),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Default toggle
            Row(
              children: [
                Switch.adaptive(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Set as default', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(
              label: _saving ? 'Adding...' : 'Add payment method',
              icon: Icons.add_rounded,
              size: AppButtonSize.lg,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;

    String? subtitle;
    String? upiId;

    if (_type == PaymentMethodType.upi) {
      upiId = _upiIdCtrl.text.trim();
      subtitle = upiId;
    } else if (_type == PaymentMethodType.card) {
      subtitle = '•••• ${_subtitleCtrl.text.trim()}';
    } else {
      subtitle = _subtitleCtrl.text.trim();
    }

    setState(() => _saving = true);

    try {
      await ref.read(paymentMethodRepositoryProvider).create(
            userId: widget.userId,
            type: _type,
            label: label,
            subtitle: (subtitle != null && subtitle!.isNotEmpty) ? subtitle : null,
            upiId: (upiId != null && upiId!.isNotEmpty) ? upiId : null,
            lastFour: _type == PaymentMethodType.card ? _subtitleCtrl.text.trim() : null,
            isDefault: _isDefault,
          );

      ref.invalidate(_paymentMethodsProvider(widget.userId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$label"'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add method: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// Provider for fetching payment methods
final _paymentMethodsProvider = FutureProvider.autoDispose
    .family<List<PaymentMethod>, String>((ref, userId) async {
  return ref.watch(paymentMethodRepositoryProvider).listByUser(userId);
});
