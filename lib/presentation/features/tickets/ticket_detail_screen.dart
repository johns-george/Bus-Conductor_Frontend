import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/ticket.dart';
import '../../providers/repository_providers.dart';
import '../auth/auth_controller.dart';
import '../wallet/wallet_screen.dart' show walletTransactionsProvider, walletTabProvider;
import '../../widgets/badges/status_badge.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';

/// Ticket detail — the scannable QR, passenger info, route summary, and
/// cancellation policy. Also used as the "success" screen after booking.
class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.showSuccess = false,
  });

  final String ticketId;
  final bool showSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final async = ref.watch(ticketByIdProvider(ticketId));

    return Scaffold(
      backgroundColor: palette.background,
      body: async.when(
        loading: () => const _Loading(),
        error: (e, _) => _Missing(message: '$e'),
        data: (t) {
          if (t == null) {
            return const _Missing(message: 'Ticket not found or expired.');
          }
          return _TicketBody(ticket: t, showSuccess: showSuccess);
        },
      ),
    );
  }
}

final ticketByIdProvider =
    FutureProvider.autoDispose.family<Ticket?, String>((ref, id) {
  return ref.watch(ticketRepositoryProvider).byId(id);
});

class _TicketBody extends ConsumerWidget {
  const _TicketBody({required this.ticket, required this.showSuccess});
  final Ticket ticket;
  final bool showSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final token = ticket.qrToken ?? 'bc:ticket:${ticket.id}';
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: showSuccess ? AppColors.success : AppColors.midnight,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(AppIcons.back, color: Colors.white),
            onPressed: () {
              if (showSuccess) {
                context.go('/tickets');
              } else {
                context.pop();
              }
            },
          ),
          expandedHeight: showSuccess ? 180 : 120,
          title: Text(showSuccess ? 'Booking confirmed' : 'Your ticket'),
          actions: [
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: showSuccess
                ? _SuccessHero()
                : _DefaultHeader(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList.list(
            children: [
              // QR card — only for active tickets
              if (ticket.status == TicketStatus.active ||
                  ticket.status == TicketStatus.pendingValidation) ...[
                _QrCard(token: token, ticket: ticket),
                const SizedBox(height: AppSpacing.lg),
              ],
              _TicketInfoCard(ticket: ticket),
              const SizedBox(height: AppSpacing.lg),
              _FareCard(ticket: ticket),
              const SizedBox(height: AppSpacing.xl),
              if (showSuccess) ...[
                PrimaryButton(
                  label: 'View all tickets',
                  icon: AppIcons.ticket,
                  size: AppButtonSize.lg,
                  onPressed: () => context.go('/tickets'),
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: 'Back to home',
                  icon: AppIcons.home,
                  size: AppButtonSize.lg,
                  onPressed: () => context.go('/home'),
                ),
              ] else if (ticket.status == TicketStatus.active ||
                  ticket.status == TicketStatus.pendingValidation) ...[
                SecondaryButton(
                  label: 'Show to conductor',
                  icon: AppIcons.qr,
                  size: AppButtonSize.lg,
                  onPressed: () => _showFullscreenQr(context, token),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              // Edit button — only for pending tickets
              if (!showSuccess &&
                  ticket.status == TicketStatus.pendingValidation) ...[
                _EditButton(ticket: ticket),
                const SizedBox(height: AppSpacing.md),
              ],
              // Cancel button — for pending and active tickets
              if (!showSuccess &&
                  (ticket.status == TicketStatus.active ||
                      ticket.status == TicketStatus.pendingValidation))
                _CancelButton(ticketId: ticket.id),
              const SizedBox(height: AppSpacing.xl),
              // Expiry / status message
              if (ticket.status == TicketStatus.active ||
                  ticket.status == TicketStatus.pendingValidation)
                _ExpiryCountdown(expiresAt: ticket.expiresAt),
              if (ticket.status == TicketStatus.expired)
                Text(
                  'Ticket has expired.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (ticket.status == TicketStatus.cancelled)
                Text(
                  'Ticket has been cancelled.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (ticket.status == TicketStatus.validated)
                Text(
                  'Ticket already used.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullscreenQr(BuildContext context, String token) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenQr(token: token),
      ),
    );
  }
}

class _DefaultHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.midnight, AppColors.midnightSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.success, AppColors.tealStrong],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.55),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 32,),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment successful',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.token, required this.ticket});
  final String token;
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final statusTone = switch (ticket.status) {
      TicketStatus.active => StatusTone.success,
      TicketStatus.pendingValidation => StatusTone.warning,
      TicketStatus.validated => StatusTone.info,
      TicketStatus.expired => StatusTone.neutral,
      TicketStatus.cancelled => StatusTone.error,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.id,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    Text(ticket.route.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,),
                  ],
                ),
              ),
              StatusBadge(label: ticket.status.label, tone: statusTone),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.rMd,
              border: Border.all(color: palette.border),
            ),
            child: QrImageView(
              data: token,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.midnight,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.midnight,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Show this QR at boarding. Brightness auto-adjusts on supported devices.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketInfoCard extends StatelessWidget {
  const _TicketInfoCard({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final pax = ticket.passengerCount > 0 ? ticket.passengerCount : 1;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Leg(
                  city: ticket.from.city,
                  stop: ticket.from.name,
                  time: DateFormatting.time(ticket.bookedAt),
                  alignEnd: false,
                ),
              ),
              Column(
                children: [
                  Icon(AppIcons.bus, size: 20, color: palette.textMuted),
                  Container(
                    width: 40,
                    height: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: palette.border,
                  ),
                ],
              ),
              Expanded(
                child: _Leg(
                  city: ticket.to.city,
                  stop: ticket.to.name,
                  time: DateFormatting.time(ticket.expiresAt),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          Divider(color: palette.border, height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _InfoPair(
                  label: 'Passenger',
                  value: ticket.passengerName ?? '—',
                ),
              ),
              Expanded(
                child: _InfoPair(
                  label: 'Passengers',
                  value: '$pax',
                ),
              ),
              Expanded(
                child: _InfoPair(
                  label: 'Booked',
                  value: DateFormatting.travelDate(ticket.bookedAt),
                ),
              ),
            ],
          ),
          if (ticket.bus != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadii.rSm,
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.bus,
                      color: AppColors.tealStrong, size: 18,),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${ticket.bus!.bus.number} \u00b7 ${ticket.bus!.bus.operatorName}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Leg extends StatelessWidget {
  const _Leg({
    required this.city,
    required this.stop,
    required this.time,
    required this.alignEnd,
  });
  final String city;
  final String stop;
  final String time;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          city,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.tealStrong,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          stop,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textMuted,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        ),
      ],
    );
  }
}

class _InfoPair extends StatelessWidget {
  const _InfoPair({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({required this.ticket});
  final Ticket ticket;

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
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined,
              color: AppColors.tealStrong, size: 20,),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount paid', style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),),
                Text(Money.format(ticket.fare),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Download receipt'),
          ),
        ],
      ),
    );
  }
}

class _EditButton extends ConsumerWidget {
  const _EditButton({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Edit details'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.tealStrong,
        side: BorderSide(color: AppColors.teal.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.rMd),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      onPressed: () => _showEditDialog(context, ref),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController(text: ticket.passengerName ?? '');
    final phoneCtrl = TextEditingController(text: ticket.passengerPhone ?? '');
    int count = ticket.passengerCount > 0 ? ticket.passengerCount : 1;
    final originalCount = count;

    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final palette = Theme.of(ctx).extension<AppPalette>()!.surfaces;
          final extraCount = count - originalCount;
          final perTicketFare = originalCount > 0
              ? (ticket.fare / originalCount).round()
              : ticket.fare.round();
          final extraAmount = extraCount > 0 ? extraCount * perTicketFare : 0;

          return AlertDialog(
            title: const Text('Edit ticket details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Passenger name',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Text('Passengers: '),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: count > 1 ? () => setDialogState(() => count--) : null,
                    ),
                    Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: count < 10 ? () => setDialogState(() => count++) : null,
                    ),
                  ],
                ),
                if (extraCount > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.amberSoft,
                      borderRadius: AppRadii.rMd,
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.amberStrong, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '+$extraCount passenger${extraCount > 1 ? 's' : ''} — additional ${Money.format(extraAmount)} will be charged',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.amberStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop({
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'count': count,
                  'extraAmount': extraAmount,
                }),
                child: Text(extraAmount > 0 ? 'Pay ${Money.format(extraAmount)}' : 'Save'),
              ),
            ],
          );
        },
      ),
    );

    if (updated == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(ticketRepositoryProvider);
    final extraAmount = updated['extraAmount'] as int? ?? 0;

    try {
      if (extraAmount > 0) {
        // Need additional payment — debit from wallet
        final walletRepo = ref.read(walletRepositoryProvider);
        final session = ref.read(authSessionProvider).valueOrNull;
        if (session == null) {
          messenger.showSnackBar(const SnackBar(content: Text('Please log in to continue')));
          return;
        }
        final userId = session.user.id;
        final wallet = await walletRepo.byUser(userId);
        if (wallet.balance < extraAmount) {
          messenger.showSnackBar(const SnackBar(
            content: Text('Insufficient wallet balance. Please top up first.'),
          ));
          return;
        }
        // Debit wallet — backend automatically creates transaction record
        await walletRepo.debit(
          userId: userId,
          amount: extraAmount,
          note: 'Additional passengers for ticket #${ticket.id}',
        );
      }

      await repo.editTicket(
        ticketId: ticket.id,
        passengerName: updated['name'] as String?,
        passengerPhone: updated['phone'] as String?,
        passengerCount: updated['count'] as int?,
      );
      ref.invalidate(ticketByIdProvider(ticket.id));
      ref.read(ticketRefreshProvider.notifier).state++;
      ref.invalidate(walletTransactionsProvider);
      ref.invalidate(walletTabProvider);

      if (extraAmount > 0) {
        messenger.showSnackBar(SnackBar(
          content: Text('Updated! ${Money.format(extraAmount)} charged for additional passengers.'),
        ));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Ticket updated')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }
}

class _CancelButton extends ConsumerWidget {
  const _CancelButton({required this.ticketId});
  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.cancel_outlined, size: 18),
      label: const Text('Cancel ticket'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.rMd),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      onPressed: () => _confirmCancel(context, ref),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel ticket?'),
        content: const Text(
          'This will cancel your ticket and refund the amount to your wallet. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep ticket'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel ticket'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(ticketRepositoryProvider);
    final result = await repo.cancelTicket(ticketId);

    if (!context.mounted) return;

    if (result.success) {
      ref.invalidate(ticketByIdProvider(ticketId));
      ref.read(ticketRefreshProvider.notifier).state++;
      ref.invalidate(walletTransactionsProvider);
      ref.invalidate(walletTabProvider);

      final msg = result.refundAmount != null
          ? 'Ticket cancelled. ${Money.format(result.refundAmount!)} refunded to wallet.'
          : 'Ticket cancelled successfully.';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Cancel failed')),
      );
    }
  }
}

class _ExpiryCountdown extends StatefulWidget {
  const _ExpiryCountdown({required this.expiresAt});
  final DateTime expiresAt;

  @override
  State<_ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<_ExpiryCountdown> {
  @override
  void initState() {
    super.initState();
    // Update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  late final Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now().toUtc();
    final expiresUtc = widget.expiresAt.toUtc();
    final remaining = expiresUtc.difference(now);

    final isExpired = remaining.isNegative;
    final isUrgent = !isExpired && remaining.inMinutes < 30;
    final hours = remaining.inHours.abs();
    final minutes = remaining.inMinutes.remainder(60).abs();
    final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Text(
      isExpired ? 'Ticket has expired.' : 'Expires in $timeStr',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: isExpired
            ? AppColors.error
            : (isUrgent ? AppColors.amberStrong : AppColors.tealStrong),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FullscreenQr extends StatelessWidget {
  const _FullscreenQr({required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.midnight,
        elevation: 0,
        title: const Text('Scan at boarding'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: QrImageView(
            data: token,
            size: 320,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.midnight,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.midnight,
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AppShimmer(child: SkeletonBlock(height: 48, radius: AppRadii.md)),
            SizedBox(height: AppSpacing.lg),
            AppShimmer(child: SkeletonBlock(height: 280, radius: AppRadii.md)),
            SizedBox(height: AppSpacing.lg),
            AppShimmer(child: SkeletonBlock(height: 160, radius: AppRadii.md)),
          ],
        ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(AppIcons.back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const Spacer(),
            ErrorStateView(
              title: 'Ticket unavailable',
              message: message,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
