import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../domain/entities/route.dart';
import '../../../domain/entities/saved_route.dart';
import '../../../domain/entities/stop.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/cards/route_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import '../search/search_controller.dart';
import 'results_controller.dart';

/// Results page. Shows all matching routes for a searched source → destination
/// segment with loading, empty and error states, plus an editable search
/// summary header.
class RouteResultsScreen extends ConsumerStatefulWidget {
  const RouteResultsScreen({
    super.key,
    required this.from,
    required this.to,
    this.date,
  });

  final Stop from;
  final Stop to;
  final DateTime? date;

  @override
  ConsumerState<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends ConsumerState<RouteResultsScreen> {
  _ResultSort _sort = _ResultSort.departure;
  final Set<String> _savedKeys = {};

  RouteResultsRequest get _request => RouteResultsRequest(
        from: widget.from,
        to: widget.to,
        date: widget.date,
      );

  Future<void> _refresh() async {
    ref.invalidate(routeResultsProvider(_request));
    // Wait for the provider to resolve so pull-to-refresh shows a real cycle.
    await ref.read(routeResultsProvider(_request).future);
  }

  @override
  Widget build(BuildContext context) {
    final asyncResults = ref.watch(routeResultsProvider(_request));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ResultsHeader(
              from: widget.from,
              to: widget.to,
              date: widget.date,
              count: asyncResults.asData?.value.length,
              onEdit: () {
                ref.read(searchFormProvider.notifier)
                  ..setFrom(widget.from)
                  ..setTo(widget.to)
                  ..setDate(widget.date);
                context.go(AppRoutes.search);
              },
            ),
            _SortToolbar(
              sort: _sort,
              onChanged: (s) => setState(() => _sort = s),
              count: asyncResults.asData?.value.length,
            ),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: _refresh,
                child: asyncResults.when(
                  loading: () => const _LoadingList(),
                  error: (err, _) => _ErrorView(
                    message: '$err',
                    onRetry: _refresh,
                  ),
                  data: (results) {
                    if (results.isEmpty) {
                      return _EmptyView(
                        from: widget.from,
                        to: widget.to,
                        onEdit: () {
                          ref.read(searchFormProvider.notifier)
                            ..setFrom(widget.from)
                            ..setTo(widget.to)
                            ..setDate(widget.date);
                          context.go(AppRoutes.search);
                        },
                      );
                    }
                    final sorted = _applySort(results, _sort);
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xl3,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) {
                        final result = sorted[i];
                        final key =
                            '${result.searchedFrom.id}->${result.searchedTo.id}';
                        final saved = _savedKeys.contains(key);
                        return _AnimatedListItem(
                          index: i,
                          child: RouteResultCard(
                            result: result,
                            saved: saved,
                            onToggleSaved: () => _toggleSaved(result, key),
                            onTap: () => _openRoute(result),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<RouteSearchResult> _applySort(
    List<RouteSearchResult> input,
    _ResultSort sort,
  ) {
    final list = [...input];
    switch (sort) {
      case _ResultSort.departure:
        list.sort((a, b) => a.nextBusAt.compareTo(b.nextBusAt));
      case _ResultSort.fare:
        list.sort((a, b) => a.searchedFare.compareTo(b.searchedFare));
      case _ResultSort.travel:
        list.sort((a, b) => a.estimatedTravel.compareTo(b.estimatedTravel));
    }
    return list;
  }

  void _openRoute(RouteSearchResult result) {
    context.pushNamed(
      'routeDetail',
      pathParameters: {'routeId': result.route.id},
      extra: result,
    );
  }

  Future<void> _toggleSaved(RouteSearchResult r, String key) async {
    final wasSaved = _savedKeys.contains(key);
    setState(() {
      if (wasSaved) {
        _savedKeys.remove(key);
      } else {
        _savedKeys.add(key);
      }
    });
    await ref.read(routeRepositoryProvider).toggleSaved(
          SavedRoute(
            id: key,
            label: '${r.searchedFrom.name} \u2192 ${r.searchedTo.name}',
            from: r.searchedFrom,
            to: r.searchedTo,
            savedAt: DateTime.now(),
          ),
        );
    ref.invalidate(savedRoutesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(wasSaved ? 'Removed from saved' : 'Saved for later'),
          ),
        );
    }
  }
}

enum _ResultSort { departure, fare, travel }

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.from,
    required this.to,
    required this.date,
    required this.count,
    required this.onEdit,
  });

  final Stop from;
  final Stop to;
  final DateTime? date;
  final int? count;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    final dateLabel =
        date == null ? 'Flexible' : DateFormatting.travelDate(date!);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(
          bottom: BorderSide(color: palette.border),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(AppIcons.back, size: 18),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buses for',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${from.city} \u2192 ${to.city}',
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _RouteSummaryCard(
            from: from,
            to: to,
            date: date,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              StatusBadge(
                label: dateLabel,
                icon: AppIcons.calendar,
                tone: StatusTone.brand,
                dense: true,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (count != null)
                StatusBadge(
                  label: '$count ${count == 1 ? 'route' : 'routes'} found',
                  icon: AppIcons.route,
                  tone: StatusTone.neutral,
                  dense: true,
                ),
              const Spacer(),
              Text(
                'Live',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.primary, letterSpacing: 1.2),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.from,
    required this.to,
    required this.date,
  });
  final Stop from;
  final Stop to;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadii.rMd,
        color: palette.surfaceMuted,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary, width: 2),
                ),
              ),
              Container(width: 2, height: 20, color: palette.borderStrong),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: scheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  from.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  from.city,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  to.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  to.city,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortToolbar extends StatelessWidget {
  const _SortToolbar({
    required this.sort,
    required this.onChanged,
    required this.count,
  });

  final _ResultSort sort;
  final ValueChanged<_ResultSort> onChanged;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _SortChip(
            label: 'Departure time',
            active: sort == _ResultSort.departure,
            onTap: () => onChanged(_ResultSort.departure),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SortChip(
            label: 'Lowest fare',
            active: sort == _ResultSort.fare,
            onTap: () => onChanged(_ResultSort.fare),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SortChip(
            label: 'Shortest travel',
            active: sort == _ResultSort.travel,
            onTap: () => onChanged(_ResultSort.travel),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Material(
        color:
            active ? scheme.primary.withValues(alpha: 0.12) : palette.surface,
        borderRadius: AppRadii.rPill,
        child: InkWell(
          borderRadius: AppRadii.rPill,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadii.rPill,
              border: Border.all(
                color: active ? scheme.primary : palette.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.tune,
                  size: 14,
                  color: active ? scheme.primary : palette.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: active ? scheme.primary : palette.textPrimary,
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

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl3,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => const RouteCardSkeleton(),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.from,
    required this.to,
    required this.onEdit,
  });
  final Stop from;
  final Stop to;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: AppSpacing.xl2),
        EmptyState(
          title: 'No direct buses yet',
          message:
              'We couldn\u2019t find a direct route between ${from.name} and ${to.name}. Try picking a nearby stop or a different date.',
          icon: AppIcons.bus,
          action: PrimaryButton(
            label: 'Edit search',
            onPressed: onEdit,
            icon: AppIcons.search,
            expanded: false,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: AppSpacing.xl2),
        ErrorStateView(
          message: message,
          onRetry: () => onRetry(),
        ),
      ],
    );
  }
}

/// Light entry animation so results feel alive without being distracting.
class _AnimatedListItem extends StatefulWidget {
  const _AnimatedListItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(milliseconds: 40 * widget.index.clamp(0, 6)),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
