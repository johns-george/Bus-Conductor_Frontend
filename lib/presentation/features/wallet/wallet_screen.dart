import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/wallet.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/skeleton.dart';
import '../auth/auth_controller.dart';

/// Wallet tab — balance hero, quick top-up row, active passes, transactions.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;

    if (session == null) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(title: const Text('Wallet')),
        body: Center(
          child: _GuestPrompt(onLogin: () => context.go(AppRoutes.authWelcome)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push(AppRoutes.allTransactions),
            tooltip: 'All transactions',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletTabProvider);
          ref.invalidate(walletTransactionsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            120,
          ),
          children: [
            _BalanceCard(userId: session.user.id),
            const SizedBox(height: AppSpacing.lg),
            _TopupRow(userId: session.user.id),
            const SizedBox(height: AppSpacing.xl),
            _PassesSection(userId: session.user.id),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Recent activity',
              action: TextButton(
                onPressed: () => context.push(AppRoutes.allTransactions),
                child: const Text('See all'),
              ),
            ),
            _TransactionsList(),
          ],
        ),
      ),
    );
  }
}

final walletTabProvider = FutureProvider.autoDispose
    .family<Wallet, String>((ref, userId) async {
  return ref.watch(walletRepositoryProvider).byUser(userId);
});

final walletTransactionsProvider =
    FutureProvider.autoDispose<List<AppTransaction>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  return ref
      .watch(transactionRepositoryProvider)
      .byUser(session.user.id);
});

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(walletTabProvider(userId));
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.18),
                  borderRadius: AppRadii.rSm,
                ),
                alignment: Alignment.center,
                child: const Icon(AppIcons.wallet,
                    color: AppColors.teal, size: 22,),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Bus Conductor Wallet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          async.when(
            loading: () => const AppShimmer(
              child: SkeletonBlock(height: 48, radius: AppRadii.md),
            ),
            error: (e, _) => Text(
              '$e',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.errorSoft),
            ),
            data: (w) => Text(
              Money.format(w.balance),
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          async.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (w) => Text(
              'Updated ${DateFormatting.relativeTime(w.lastUpdated)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopupRow extends ConsumerWidget {
  const _TopupRow({required this.userId});
  final String userId;

  static const _amounts = [100, 200, 500, 1000];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add money', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final amt in _amounts) ...[
              Expanded(
                child: _QuickAmountTile(
                  label: Money.format(amt),
                  onTap: () => _handleTopUp(context, amt),
                ),
              ),
              if (amt != _amounts.last)
                const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: 'Custom amount',
          icon: Icons.add_rounded,
          onPressed: () => _promptCustom(context, ref),
        ),

      ],
    );
  }

  void _handleTopUp(BuildContext context, num amount) {
    context.push(AppRoutes.walletTopup, extra: amount);
  }

  Future<void> _promptCustom(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(sheetCtx).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add custom amount',
                  style: Theme.of(sheetCtx).textTheme.titleMedium,),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  prefixText: '\u20B9 ',
                  hintText: 'e.g. 250',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Continue to payment',
                icon: AppIcons.wallet,
                size: AppButtonSize.lg,
                onPressed: () {
                  final parsed = num.tryParse(controller.text);
                  if (parsed == null || parsed <= 0) {
                    Navigator.of(sheetCtx).pop();
                    return;
                  }
                  Navigator.of(sheetCtx).pop(parsed);
                },
              ),
            ],
          ),
        );
      },
    );
    if (amount != null && context.mounted) {
      _handleTopUp(context, amount);
    }
  }
}

class _QuickAmountTile extends StatelessWidget {
  const _QuickAmountTile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Material(
      color: palette.surface,
      borderRadius: AppRadii.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.rMd,
            border: Border.all(color: palette.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PassesSection extends ConsumerWidget {
  const _PassesSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final async = ref.watch(walletTabProvider(userId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Active passes',
          subtitle: 'Unlimited rides across operators',
        ),
        async.when(
          loading: () => const AppShimmer(
            child: SkeletonBlock(height: 96, radius: AppRadii.md),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (w) {
            if (w.passes.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.rLg,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3A4A), Color(0xFF0D2B36)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.18),
                            borderRadius: AppRadii.rMd,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.card_membership_rounded,
                            color: AppColors.amber,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly passes — coming soon',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Unlimited rides across all routes. This feature is not available yet.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _passBenefit(Icons.all_inclusive_rounded, 'Unlimited rides'),
                        const SizedBox(width: AppSpacing.md),
                        _passBenefit(Icons.savings_rounded, 'Save 20%'),
                        const SizedBox(width: AppSpacing.md),
                        _passBenefit(Icons.speed_rounded, 'Skip the queue'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: AppRadii.rSm,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: w.passes.map((p) {
                final left = p.validTill.difference(DateTime.now()).inDays;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.rMd,
                    gradient: const LinearGradient(
                      colors: [AppColors.amberSoft, AppColors.tealSoft],
                    ),
                    border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: AppColors.amberStrong, size: 24,),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.label,
                                style: theme.textTheme.titleSmall,),
                            const SizedBox(height: 2),
                            Text(
                              '${p.ridesRemaining} rides left \u00b7 ${left <= 0 ? "expired" : "$left day${left == 1 ? "" : "s"} left"}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TransactionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletTransactionsProvider);
    return async.when(
      loading: () => const AppShimmer(
        child: SkeletonBlock(height: 80, radius: AppRadii.md),
      ),
      error: (e, _) => ErrorStateView(
        title: 'Could not load transactions',
        message: '$e',
        onRetry: () => ref.invalidate(walletTransactionsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No transactions yet',
            message: 'Your payments and top-ups will show up here.',
          );
        }
        return Column(
          children: items
              .take(10)
              .map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _TransactionTile(transaction: t),
                  ),)
              .toList(),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final AppTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final isCredit = transaction.type == TransactionType.topup ||
        transaction.type == TransactionType.refund;
    final tone = switch (transaction.status) {
      TransactionStatus.successful => isCredit ? AppColors.success : AppColors.coral,
      TransactionStatus.pending => AppColors.amberStrong,
      TransactionStatus.failed => AppColors.error,
      TransactionStatus.refunded => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.18),
              borderRadius: AppRadii.rSm,
            ),
            alignment: Alignment.center,
            child: Icon(
              isCredit ? Icons.add_rounded : Icons.arrow_outward_rounded,
              color: tone,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note ?? transaction.methodType.label,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${DateFormatting.relativeTime(transaction.createdAt)} \u00b7 ${transaction.methodLabel ?? transaction.methodType.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? "+" : "-"}${Money.format(transaction.amount)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              StatusBadge(
                label: transaction.status.label,
                tone: switch (transaction.status) {
                  TransactionStatus.successful => StatusTone.success,
                  TransactionStatus.pending => StatusTone.warning,
                  TransactionStatus.failed => StatusTone.error,
                  TransactionStatus.refunded => StatusTone.info,
                },
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Padding(
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
            child: const Icon(AppIcons.wallet,
                color: AppColors.tealStrong, size: 34,),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Your wallet is ready', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Log in to top up, buy passes, and track transactions.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Log in',
            icon: AppIcons.profile,
            expanded: false,
            onPressed: onLogin,
          ),
        ],
      ),
    );
  }
}

Widget _passBenefit(IconData icon, String label) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: AppRadii.rSm,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.teal, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
