import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/route.dart';
import '../../../domain/entities/saved_route.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/common/date_chip_row.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/skeleton.dart';
import '../auth/auth_controller.dart';
import '../search/search_controller.dart';
import '../search/widgets/search_panel.dart';

/// Home tab — the signed-in landing page.
/// Acts as the launchpad for search, saved routes, popular routes, and quick
/// actions. Keeps its own scroll and reuses domain providers where possible.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;
    final userName = session?.user.displayName ?? 'Traveller';
    final searchDate = ref.watch(searchFormProvider).date;

    return Scaffold(
      backgroundColor: palette.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedRoutesProvider);
          ref.invalidate(recentSearchesProvider);
          ref.invalidate(popularRoutesProvider);
          await Future<void>.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(name: userName, isGuest: session == null),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: SearchPanel(
                  onSubmit: (from, to, date) {
                    context.pushNamed(
                      'routeResults',
                      extra: RouteResultsArgs(
                        from: from,
                        to: to,
                        date: date,
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: DateChipRow(
                  selected: searchDate,
                  onSelected: (d) =>
                      ref.read(searchFormProvider.notifier).setDate(d),
                  onPickCustom: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: searchDate ?? now,
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
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            const SliverToBoxAdapter(child: _QuickActionsRow()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            const SliverToBoxAdapter(child: _SavedRoutesSection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            const SliverToBoxAdapter(child: _PopularRoutesSection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            const SliverToBoxAdapter(child: _TipCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

/// Live feed of popular routes for the Home landing. Pulls seeded/mocked data
/// today; becomes a server-driven recommendations feed in production.
final popularRoutesProvider =
    FutureProvider.autoDispose<List<RouteSearchResult>>((ref) {
  final repo = ref.watch(routeRepositoryProvider);
  return repo.popularSuggestions(limit: 4);
});

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.name, required this.isGuest});
  final String name;
  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          0,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                borderRadius: AppRadii.rMd,
                gradient: LinearGradient(
                  colors: [AppColors.teal, AppColors.tealStrong],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initialsOf(name),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  Text(
                    isGuest ? 'Welcome, Guest' : 'Hi, ${name.split(' ').first}',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            _IconPill(
              icon: Icons.notifications_none_rounded,
              onTap: () => context.push(AppRoutes.notifications),
              hasDot: true,
            ),
          ],
        ),
      ),
    );
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return (parts.first.isNotEmpty ? parts.first[0] : '') +
        (parts.last.isNotEmpty ? parts.last[0] : '');
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _IconPill extends StatelessWidget {
  const _IconPill({required this.icon, required this.onTap, this.hasDot = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Material(
      color: palette.surface,
      borderRadius: AppRadii.rSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rSm,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: AppRadii.rSm,
            border: Border.all(color: palette.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: palette.textPrimary),
              if (hasDot)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final items = <_QuickAction>[
      _QuickAction(
        icon: AppIcons.ticket,
        label: 'My tickets',
        tone: AppColors.amber,
        onTap: () => GoRouter.of(context).go(AppRoutes.tickets),
      ),
      _QuickAction(
        icon: AppIcons.wallet,
        label: 'Wallet',
        tone: AppColors.info,
        onTap: () => GoRouter.of(context).go(AppRoutes.transactions),
      ),
      _QuickAction(
        icon: AppIcons.route,
        label: 'Routes',
        tone: AppColors.coral,
        onTap: () => GoRouter.of(context).push(AppRoutes.search),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final a in items)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: a == items.last ? 0 : AppSpacing.sm,
                ),
                child: _QuickActionButton(action: a),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction {
  _QuickAction({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Material(
      color: palette.surface,
      borderRadius: AppRadii.rMd,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: AppRadii.rMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.rMd,
            border: Border.all(color: palette.border),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.tone.withValues(alpha: 0.15),
                  borderRadius: AppRadii.rSm,
                ),
                alignment: Alignment.center,
                child: Icon(action.icon, size: 18, color: action.tone),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                action.label,
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedRoutesSection extends ConsumerWidget {
  const _SavedRoutesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedRoutesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: async.when(
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Saved routes'),
            AppShimmer(child: SkeletonBlock(height: 84, radius: AppRadii.md)),
          ],
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (items) {
          if (items.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'Saved routes'),
                _EmptySaved(onSearch: () =>
                    GoRouter.of(context).push(AppRoutes.search),),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Saved routes'),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, i) => _SavedRouteCard(saved: items[i]),
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemCount: items.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
        color: palette.surface,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: AppRadii.rSm,
            ),
            child: const Icon(AppIcons.heartOutline,
                color: AppColors.tealStrong, size: 20,),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No saved routes yet',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Star routes from search results to find them here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onSearch, child: const Text('Search')),
        ],
      ),
    );
  }
}

class _SavedRouteCard extends ConsumerWidget {
  const _SavedRouteCard({required this.saved});
  final SavedRoute saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return SizedBox(
      width: 260,
      child: Material(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        child: InkWell(
          borderRadius: AppRadii.rMd,
          onTap: () {
            ref.read(searchFormProvider.notifier)
              ..setFrom(saved.from)
              ..setTo(saved.to);
            GoRouter.of(context).pushNamed(
              'routeResults',
              extra: RouteResultsArgs(from: saved.from, to: saved.to),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadii.rMd,
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.heart,
                        color: AppColors.coral, size: 16,),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        saved.label,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${saved.from.name} → ${saved.to.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  'Saved ${DateFormatting.relativeTime(saved.savedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopularRoutesSection extends ConsumerWidget {
  const _PopularRoutesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(popularRoutesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: async.when(
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Popular right now'),
            AppShimmer(child: SkeletonBlock(height: 96, radius: AppRadii.md)),
            SizedBox(height: AppSpacing.md),
            AppShimmer(child: SkeletonBlock(height: 96, radius: AppRadii.md)),
          ],
        ),
        error: (e, __) => ErrorStateView(
          title: 'Could not load suggestions',
          message: '$e',
          onRetry: () => ref.invalidate(popularRoutesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: AppIcons.route,
              title: 'Nothing trending yet',
              message: 'Popular routes will show up here as commuters ride.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'Popular right now',
                subtitle: '${items.length} routes trending in your city',
              ),
              ...items.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PopularRouteCard(result: r),
                  ),),
            ],
          );
        },
      ),
    );
  }
}

class _PopularRouteCard extends ConsumerWidget {
  const _PopularRouteCard({required this.result});
  final RouteSearchResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final eta = DateFormatting.relativeTime(result.nextBusAt);
    return Material(
      color: palette.surface,
      borderRadius: AppRadii.rMd,
      child: InkWell(
        borderRadius: AppRadii.rMd,
        onTap: () {
          GoRouter.of(context).pushNamed(
            'routeDetail',
            pathParameters: {'routeId': result.route.id},
            extra: result,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.rMd,
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: AppRadii.rSm,
                ),
                alignment: Alignment.center,
                child: const Icon(AppIcons.bus,
                    size: 22, color: AppColors.tealStrong,),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.route.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${result.searchedFrom.name} → ${result.searchedTo.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(AppIcons.clock,
                            size: 12, color: palette.textMuted,),
                        const SizedBox(width: 4),
                        Text(
                          'Next bus $eta',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.format(result.searchedFare),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.tealStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.searchedDistanceKm.toStringAsFixed(1)} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
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
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadii.rLg,
          color: AppColors.amberSoft,
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.25),
                borderRadius: AppRadii.rSm,
              ),
              child:
                  const Icon(AppIcons.info, color: AppColors.amberStrong, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly passes coming soon',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF5C4800),
                        fontWeight: FontWeight.w700,
                      ),),
                  const SizedBox(height: 2),
                  Text(
                    'Unlimited rides across all routes. This feature is not available yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7A6530),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
