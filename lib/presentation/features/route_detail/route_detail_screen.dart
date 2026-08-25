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
import '../../../domain/entities/bus.dart';
import '../../../domain/entities/route.dart';
import '../../../domain/entities/saved_route.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/skeleton.dart';
import '../auth/auth_controller.dart';
import '../booking/booking_controller.dart';
import '../search/search_controller.dart';
import 'route_detail_controller.dart';

/// Detailed view of a single route: header summary, full stop timeline, and
/// the live upcoming buses. Can be reached from Home, Results, and deep links.
class RouteDetailScreen extends ConsumerWidget {
  const RouteDetailScreen({
    super.key,
    required this.routeId,
    this.initialResult,
  });

  final String routeId;

  /// Optional pre-fetched search result to avoid a round-trip when the user
  /// comes from a list of results.
  final RouteSearchResult? initialResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final async = initialResult != null
        ? AsyncValue<BusRoute?>.data(initialResult!.route)
        : ref.watch(routeByIdProvider(routeId));

    return Scaffold(
      backgroundColor: palette.background,
      body: async.when(
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(message: '$e'),
        data: (route) {
          if (route == null) {
            return const _ErrorView(
              message: 'Route not found or no longer active.',
            );
          }
          return _RouteDetailBody(
            route: route,
            initialResult: initialResult,
          );
        },
      ),
    );
  }
}

class _RouteDetailBody extends ConsumerStatefulWidget {
  const _RouteDetailBody({required this.route, this.initialResult});
  final BusRoute route;
  final RouteSearchResult? initialResult;

  @override
  ConsumerState<_RouteDetailBody> createState() => _RouteDetailBodyState();
}

class _RouteDetailBodyState extends ConsumerState<_RouteDetailBody> {
  late bool _saved;

  @override
  void initState() {
    super.initState();
    _saved = ref
        .read(routeRepositoryProvider)
        .isSaved(widget.route.origin.id, widget.route.destination.id);
  }

  Future<void> _toggleSave() async {
    final repo = ref.read(routeRepositoryProvider);
    await repo.toggleSaved(
      SavedRoute(
        id: widget.route.id,
        label: widget.route.name,
        from: widget.route.origin,
        to: widget.route.destination,
        savedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saved =
          repo.isSaved(widget.route.origin.id, widget.route.destination.id);
    });
    ref.invalidate(savedRoutesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final buses = ref.watch(routeBusesProvider(route.id));
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: AppColors.midnight,
          foregroundColor: Colors.white,
          expandedHeight: 180,
          leading: IconButton(
            icon: const Icon(AppIcons.back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              onPressed: _toggleSave,
              tooltip: _saved ? 'Remove from saved' : 'Save route',
              icon: Icon(
                _saved ? AppIcons.heart : AppIcons.heartOutline,
                color: _saved ? AppColors.coral : Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background:
                _RouteHeader(route: route, result: widget.initialResult),
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
              _RouteStatsRow(route: route, result: widget.initialResult),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'All stops',
                subtitle: '${route.stops.length} stops along this route',
              ),
              _StopsTimeline(route: route),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Upcoming buses',
                subtitle: 'Live schedules for today',
                action: TextButton.icon(
                  onPressed: () => ref.invalidate(routeBusesProvider(route.id)),
                  icon: const Icon(AppIcons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ),
              buses.when(
                loading: () => const Column(
                  children: [
                    AppShimmer(
                      child: SkeletonBlock(height: 96, radius: AppRadii.md),
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppShimmer(
                      child: SkeletonBlock(height: 96, radius: AppRadii.md),
                    ),
                  ],
                ),
                error: (e, _) => ErrorStateView(
                  title: 'Could not load buses',
                  message: '$e',
                  onRetry: () => ref.invalidate(routeBusesProvider(route.id)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: AppIcons.bus,
                      title: 'No more buses today',
                      message: 'Check back tomorrow for the next schedule.',
                    );
                  }
                  // Segment defaults: if the user searched a specific leg we
                  // honour it, otherwise we default to the full route.
                  final segFrom =
                      widget.initialResult?.searchedFrom ?? route.origin;
                  final segTo =
                      widget.initialResult?.searchedTo ?? route.destination;
                  return Column(
                    children: [
                      for (final bus in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _UpcomingBusCard(
                            detail: bus,
                            onTap: () {
                              context.push(
                                '/bus/${bus.bus.id}',
                                extra: BusDetailArgs(
                                  detail: bus,
                                  route: route,
                                  from: segFrom,
                                  to: segTo,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl2),
              PrimaryButton(
                label: 'Book Route Ticket',
                icon: AppIcons.ticket,
                size: AppButtonSize.lg,
                onPressed: () async {
                  // Wait briefly for session to load if still streaming
                  final sessionAsync = ref.read(authSessionProvider);
                  final session = sessionAsync.valueOrNull;
                  if (sessionAsync is AsyncLoading) {
                    // Session still loading — show loading then retry
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checking login status...'),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(16),
                      ),
                    );
                    await Future<void>.delayed(const Duration(milliseconds: 500));
                  }
                  final resolved = ref.read(authSessionProvider).valueOrNull;
                  if (resolved == null) {
                    if (!context.mounted) return;
                    context.push(
                      '${AppRoutes.login}?returnTo=${Uri.encodeComponent('/booking/payment')}',
                    );
                    return;
                  }
                  ref
                      .read<BookingController>(
                        bookingControllerProvider.notifier,
                      )
                      .start(
                        route: route,
                        from: route.origin,
                        to: route.destination,
                      );
                  if (!context.mounted) return;
                  context.push('/booking/route');
                },
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Search this route',
                icon: AppIcons.search,
                size: AppButtonSize.lg,
                onPressed: () {
                  ref.read(searchFormProvider.notifier)
                    ..setFrom(route.origin)
                    ..setTo(route.destination);
                  context.pop();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Fares and timings are illustrative. Live data arrives with backend integration.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.route, required this.result});
  final BusRoute route;
  final RouteSearchResult? result;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.midnight, AppColors.midnightSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          right: -40,
          top: -20,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          left: -30,
          bottom: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber.withValues(alpha: 0.08),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl4,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (route.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: route.tags
                      .map(
                        (t) => StatusBadge(
                          label: t,
                          tone: StatusTone.info,
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                route.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${route.origin.city} → ${route.destination.city}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteStatsRow extends StatelessWidget {
  const _RouteStatsRow({required this.route, this.result});
  final BusRoute route;
  final RouteSearchResult? result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    // Use searched segment values when available (from search results),
    // otherwise fall back to full route values.
    final displayDistance = result?.searchedDistanceKm ?? route.distanceKm;
    final displayFare = result?.searchedFare ?? route.fare;
    final stats = [
      _Stat(
        icon: AppIcons.route,
        label: 'Distance',
        value: '${displayDistance.toStringAsFixed(1)} km',
      ),
      _Stat(
        icon: AppIcons.bus,
        label: 'Stops',
        value: '${route.stops.length}',
      ),
      _Stat(
        icon: Icons.payments_outlined,
        label: 'Fare from',
        value: Money.format(displayFare),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(child: _StatView(stat: stats[i])),
            if (i < stats.length - 1)
              Container(
                width: 1,
                height: 36,
                color: palette.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

class _StatView extends StatelessWidget {
  const _StatView({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Column(
      children: [
        Icon(stat.icon, size: 20, color: AppColors.tealStrong),
        const SizedBox(height: AppSpacing.xs),
        Text(
          stat.value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          stat.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StopsTimeline extends StatelessWidget {
  const _StopsTimeline({required this.route});
  final BusRoute route;

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
          for (var i = 0; i < route.stops.length; i++)
            _TimelineStop(
              stop: route.stops[i].name,
              subtitle: route.stops[i].area ?? route.stops[i].city,
              isFirst: i == 0,
              isLast: i == route.stops.length - 1,
              index: i + 1,
              total: route.stops.length,
              theme: theme,
              palette: palette,
            ),
        ],
      ),
    );
  }
}

class _TimelineStop extends StatelessWidget {
  const _TimelineStop({
    required this.stop,
    required this.subtitle,
    required this.isFirst,
    required this.isLast,
    required this.index,
    required this.total,
    required this.theme,
    required this.palette,
  });

  final String stop;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final int index;
  final int total;
  final ThemeData theme;
  final AppSurfaces palette;

  @override
  Widget build(BuildContext context) {
    final dotColor = isFirst
        ? AppColors.teal
        : isLast
            ? AppColors.coral
            : palette.borderStrong;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isFirst || isLast ? dotColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor, width: 2),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 34,
                  color: palette.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stop,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFirst)
                      const StatusBadge(
                        label: 'Origin',
                        tone: StatusTone.success,
                        dense: true,
                      )
                    else if (isLast)
                      const StatusBadge(
                        label: 'Destination',
                        tone: StatusTone.error,
                        dense: true,
                      )
                    else
                      Text(
                        'Stop $index of $total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingBusCard extends StatelessWidget {
  const _UpcomingBusCard({required this.detail, required this.onTap});
  final BusDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final eta = DateFormatting.relativeTime(detail.departureAt);
    return Material(
      color: palette.surface,
      borderRadius: AppRadii.rMd,
      child: InkWell(
        borderRadius: AppRadii.rMd,
        onTap: onTap,
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.tealSoft,
                      borderRadius: AppRadii.rSm,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      AppIcons.bus,
                      color: AppColors.tealStrong,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.bus.number,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          '${detail.bus.type.label} • ${detail.bus.operatorName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (detail.isLive)
                    const StatusBadge(
                      label: 'Live',
                      tone: StatusTone.success,
                      dense: true,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _MiniStat(
                    icon: AppIcons.clock,
                    label: 'Departs',
                    value: DateFormatting.time(detail.departureAt),
                    helper: eta,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _MiniStat(
                    icon: Icons.timer_outlined,
                    label: 'Travel',
                    value: DateFormatting.durationShort(detail.travelDuration),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: palette.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (helper != null)
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.tealStrong,
            ),
          ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(height: 80),
          AppShimmer(child: SkeletonBlock(height: 160, radius: AppRadii.md)),
          SizedBox(height: AppSpacing.md),
          AppShimmer(child: SkeletonBlock(height: 80, radius: AppRadii.md)),
          SizedBox(height: AppSpacing.md),
          AppShimmer(child: SkeletonBlock(height: 320, radius: AppRadii.md)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
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
              title: 'Route unavailable',
              message: message,
              onRetry: null,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
