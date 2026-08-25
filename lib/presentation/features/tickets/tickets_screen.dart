import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/ticket.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import '../auth/auth_controller.dart';

/// Live list of the user's tickets — tabbed into Upcoming and Past. Tapping
/// a ticket opens the full-screen ticket detail with QR.
class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;

    if (session == null) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(title: const Text('Tickets')),
        body: Center(
          child: _GuestPrompt(onLogin: () => context.go(AppRoutes.authWelcome)),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          title: const Text('Tickets'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TicketsList(upcoming: true),
            _TicketsList(upcoming: false),
          ],
        ),
      ),
    );
  }
}

final _ticketsProvider = FutureProvider.autoDispose<List<Ticket>>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) return const [];
  ref.watch(ticketRefreshProvider);
  return ref.watch(ticketRepositoryProvider).byUser(session.user.id);
});

class _TicketsList extends ConsumerWidget {
  const _TicketsList({required this.upcoming});
  final bool upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_ticketsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AppShimmer(child: SkeletonBlock(height: 110, radius: AppRadii.md)),
            SizedBox(height: AppSpacing.md),
            AppShimmer(child: SkeletonBlock(height: 110, radius: AppRadii.md)),
            SizedBox(height: AppSpacing.md),
            AppShimmer(child: SkeletonBlock(height: 110, radius: AppRadii.md)),
          ],
        ),
      ),
      error: (e, _) => ErrorStateView(
        message: '$e',
        title: 'Could not load tickets',
        onRetry: () => ref.invalidate(_ticketsProvider),
      ),
      data: (tickets) {
        final filtered = tickets.where((t) {
          final isClosed = t.status == TicketStatus.validated ||
              t.status == TicketStatus.expired ||
              t.status == TicketStatus.cancelled;
          return upcoming ? !isClosed : isClosed;
        }).toList();

        if (filtered.isEmpty) {
          return _EmptyTickets(upcoming: upcoming);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_ticketsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              120,
            ),
            itemBuilder: (_, i) => _TicketCard(ticket: filtered[i]),
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemCount: filtered.length,
          ),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
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
    final isActive = ticket.status == TicketStatus.active ||
        ticket.status == TicketStatus.pendingValidation;
    return Material(
      color: palette.surface,
      borderRadius: AppRadii.rMd,
      child: InkWell(
        borderRadius: AppRadii.rMd,
        onTap: () => context.push('/ticket/${ticket.id}'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.rMd,
            border: Border.all(
              color: isActive
                  ? AppColors.teal.withValues(alpha: 0.35)
                  : palette.border,
              width: isActive ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.route.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(
                    label: ticket.status.label,
                    tone: statusTone,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.from.name,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ticket.from.city,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Icon(
                      AppIcons.chevronRight,
                      size: 18,
                      color: palette.textMuted,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ticket.to.name,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                        Text(
                          ticket.to.city,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                color: palette.border,
                height: AppSpacing.lg,
              ),
              Row(
                children: [
                  _meta(
                    theme,
                    palette,
                    AppIcons.clock,
                    DateFormatting.travelDate(ticket.bookedAt),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _meta(
                    theme,
                    palette,
                    Icons.person_outline_rounded,
                    '${ticket.passengerCount > 0 ? ticket.passengerCount : 1} pax',
                  ),
                  const Spacer(),
                  Text(
                    Money.format(ticket.fare),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.tealStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(ThemeData theme, AppSurfaces palette, IconData icon, String v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: palette.textMuted),
        const SizedBox(width: 4),
        Text(
          v,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets({required this.upcoming});
  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        const SizedBox(height: 80),
        EmptyState(
          icon: upcoming ? AppIcons.ticket : Icons.history_rounded,
          title: upcoming ? 'No upcoming tickets' : 'No past trips yet',
          message: upcoming
              ? 'Book a route and your ticket will appear here.'
              : 'Once you travel, your past trips will show up here.',
          action: upcoming
              ? PrimaryButton(
                  label: 'Find a route',
                  icon: AppIcons.search,
                  expanded: false,
                  onPressed: () => GoRouter.of(context).push(AppRoutes.search),
                )
              : null,
        ),
      ],
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
            child: const Icon(
              AppIcons.ticket,
              color: AppColors.tealStrong,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your tickets live here',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Log in to view, share, and validate your tickets.',
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
