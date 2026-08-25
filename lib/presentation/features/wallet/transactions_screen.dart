import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/transaction.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/common/empty_state.dart';
import '../auth/auth_controller.dart';

/// Full transaction history screen — shows all transactions with filter tabs.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionType? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Transaction history'),
      ),
      body: session == null
          ? Center(
              child: EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'Not logged in',
                message: 'Log in to view your transactions.',
              ),
            )
          : Column(
              children: [
                // Filter tabs
                _FilterTabs(
                  current: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
                // Transaction list
                Expanded(
                  child: _TransactionsList(
                    userId: session.user.id,
                    filter: _filter,
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.current, required this.onChanged});
  final TransactionType? current;
  final void Function(TransactionType?) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final filters = [
      (null, 'All'),
      (TransactionType.topup, 'Top-ups'),
      (TransactionType.refund, 'Refunds'),
      (TransactionType.booking, 'Bookings'),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (ctx, i) {
          final (type, label) = filters[i];
          final selected = current == type;
          return GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.tealStrong : palette.surfaceMuted,
                borderRadius: AppRadii.rSm,
                border: Border.all(
                  color: selected ? AppColors.teal : palette.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : palette.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionsList extends ConsumerWidget {
  const _TransactionsList({required this.userId, this.filter});
  final String userId;
  final TransactionType? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_allTransactionsProvider(userId));
    final theme = Theme.of(context);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: AppSpacing.pageAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load transactions',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('$e', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref.invalidate(_allTransactionsProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        final filtered = filter == null
            ? items
            : items.where((t) => t.type == filter).toList();

        if (filtered.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.receipt_long_rounded,
              title: filter == null ? 'No transactions yet' : 'No ${filter!.label.toLowerCase()} found',
              message: filter == null
                  ? 'Your payments, top-ups, and refunds will show up here.'
                  : 'Try a different filter.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (ctx, i) => _TransactionTile(transaction: filtered[i]),
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

    final typeLabel = switch (transaction.type) {
      TransactionType.topup => 'Wallet top-up',
      TransactionType.refund => 'Refund',
      TransactionType.booking => 'Booking',
      TransactionType.debit => 'Debit',
      null => 'Transaction',
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
                  transaction.note ?? typeLabel,
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

final _allTransactionsProvider = FutureProvider.autoDispose
    .family<List<AppTransaction>, String>((ref, userId) async {
  return ref.watch(transactionRepositoryProvider).byUser(userId);
});
