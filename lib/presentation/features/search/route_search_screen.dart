import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../domain/entities/saved_route.dart';
import '../../widgets/common/date_chip_row.dart';
import 'search_controller.dart';
import 'widgets/recent_searches_section.dart';
import 'widgets/search_panel.dart';

/// First-run landing experience. Browsable for guests — auth is only gated at
/// ticket/profile/booking boundaries in later phases.
class RouteSearchScreen extends ConsumerWidget {
  const RouteSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchFormProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(onNotifications: () {})),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: SearchPanel(
                  onSubmit: (from, to, date) {
                    context.pushNamed(
                      'routeResults',
                      extra: RouteResultsArgs(from: from, to: to, date: date),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  bottom: AppSpacing.md,
                ),
                child: DateChipRow(
                  selected: state.date,
                  onSelected: (d) =>
                      ref.read(searchFormProvider.notifier).setDate(d),
                  onPickCustom: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: state.date ?? now,
                      firstDate: now.subtract(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      ref.read(searchFormProvider.notifier).setDate(picked);
                    }
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _GuestBanner(
                onLogin: () => context.go(AppRoutes.authWelcome),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl3,
              ),
              sliver: SliverList.list(
                children: [
                  RecentSearchesSection(
                    onSelect: (RecentSearch r) {
                      ref.read(searchFormProvider.notifier)
                        ..setFrom(r.from)
                        ..setTo(r.to);
                      context.pushNamed(
                        'routeResults',
                        extra: RouteResultsArgs(
                          from: r.from,
                          to: r.to,
                          date: ref.read(searchFormProvider).date,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const PopularSuggestionsSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _TravelTipCard(date: state.date),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications});
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, AppColors.tealStrong],
              ),
              borderRadius: AppRadii.rMd,
            ),
            child: const Icon(AppIcons.bus,
                color: AppColors.midnightDeep, size: 22,),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_greetingSlot()}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.textMuted),
                ),
                Text(
                  'Where are you headed?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadii.rSm,
                border: Border.all(color: palette.border),
              ),
              child: Icon(Icons.notifications_none_rounded,
                  size: 20, color: palette.textPrimary,),
            ),
          ),
        ],
      ),
    );
  }

  static String _greetingSlot() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadii.rMd,
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              scheme.primary.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.explore_rounded, color: scheme.primary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exploring as guest',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Log in to book, view tickets, and save routes.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onLogin,
              child: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelTipCard extends StatelessWidget {
  const _TravelTipCard({required this.date});
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final label = date == null
        ? 'Travelling anytime'
        : 'Travelling ${DateFormatting.travelDate(date!)}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadii.rLg,
        color: palette.surface,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.15),
              borderRadius: AppRadii.rSm,
            ),
            child: Icon(AppIcons.info, color: scheme.secondary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Fares and next-bus times update live. Pick a date above to plan ahead.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
