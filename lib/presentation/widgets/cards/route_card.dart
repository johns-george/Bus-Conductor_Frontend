import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/entities/route.dart';
import '../../providers/repository_providers.dart';
import '../badges/status_badge.dart';
import '../common/app_card.dart';
import '../common/info_row.dart';

/// Primary list card used on Route Results. Shows the searched segment, fare,
/// next-bus time and supporting metrics in a scannable two-row layout.
class RouteResultCard extends ConsumerStatefulWidget {
  const RouteResultCard({
    super.key,
    required this.result,
    required this.onTap,
    this.saved = false,
    this.onToggleSaved,
  });
  final RouteSearchResult result;
  final VoidCallback onTap;
  final bool saved;
  final VoidCallback? onToggleSaved;

  @override
  ConsumerState<RouteResultCard> createState() => _RouteResultCardState();
}

class _RouteResultCardState extends ConsumerState<RouteResultCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Pre-fetch bus data when card is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(busRepositoryProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: widget.onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.result.route.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.result.route.origin.city} \u2192 ${widget.result.route.destination.city}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: palette.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (widget.onToggleSaved != null)
                  IconButton(
                    tooltip: widget.saved ? 'Remove from saved' : 'Save route',
                    onPressed: widget.onToggleSaved,
                    icon: Icon(
                      widget.saved ? AppIcons.heart : AppIcons.heartOutline,
                      color: widget.saved
                          ? scheme.tertiary
                          : palette.textSecondary,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                // Expand/Collapse button
                IconButton(
                  tooltip: _isExpanded ? 'Collapse' : 'Expand',
                  onPressed: () {
                    setState(() => _isExpanded = !_isExpanded);
                    // Invalidate bus repository to fetch fresh data when expanding
                    ref.invalidate(busRepositoryProvider);
                  },
                  icon: Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: palette.textSecondary,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          _SegmentTimeline(result: widget.result),
          const Divider(height: 1),
          // Expanded bus details section
          if (_isExpanded) ..._buildBusDetails(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(
                        icon: AppIcons.clock,
                        label: 'Next bus',
                        value: DateFormatting.time(widget.result.nextBusAt),
                        accent: widget.result.isDepartingSoon
                            ? AppColors.amberStrong
                            : scheme.primary,
                      ),
                    ),
                    Expanded(
                      child: InfoRow(
                        icon: AppIcons.route,
                        label: 'Distance',
                        value:
                            '${widget.result.searchedDistanceKm.toStringAsFixed(1)} km',
                      ),
                    ),
                    Expanded(
                      child: InfoRow(
                        icon: AppIcons.bus,
                        label: 'Travel',
                        value: DateFormatting.durationShort(
                          widget.result.estimatedTravel,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _Tag(label: '${widget.result.totalBusesToday} buses today'),
                    const SizedBox(width: AppSpacing.sm),
                    if (widget.result.route.tags.isNotEmpty)
                      _Tag(label: widget.result.route.tags.first),
                    const Spacer(),
                    Text(
                      Money.format(widget.result.searchedFare),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBusDetails(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    
    // Fetch buses for this route
    final busesAsync = ref.watch(
      FutureProvider<List<BusDetail>>((ref) async {
        return await ref.read(busRepositoryProvider).byRoute(widget.result.route.id);
      }),
    );
    
    return [
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadii.rMd,
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Available Buses',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // List of all buses for this route
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadii.rSm,
              ),
              child: busesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Unable to load buses',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ),
                data: (buses) {
                  if (buses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No buses available for this route',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: buses.asMap().entries.map((MapEntry<int, BusDetail> entry) {
                      final busDetail = entry.value;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: AppRadii.rSm,
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  busDetail.bus.number,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    busDetail.bus.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    'Departure: ${DateFormatting.time(busDetail.departureAt)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: palette.textMuted,
                                        ),
                                  ),

                                ],
                              ),
                            ),
                            if (busDetail.isLive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.amberStrong,
                                  borderRadius: AppRadii.rPill,
                                ),
                                child: Text(
                                  'LIVE',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _SegmentTimeline extends StatelessWidget {
  const _SegmentTimeline({required this.result});
  final RouteSearchResult result;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(color: scheme.primary),
              Container(width: 2, height: 22, color: palette.border),
              _Dot(
                color: scheme.tertiary,
                filled: true,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.searchedFrom.name,
                  style: theme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  result.searchedFrom.city,
                  style: theme.bodySmall?.copyWith(color: palette.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.searchedTo.name,
                  style: theme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  result.searchedTo.city,
                  style: theme.bodySmall?.copyWith(color: palette.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (result.isDepartingSoon)
            const StatusBadge(
              label: 'Departing soon',
              tone: StatusTone.warning,
              dense: true,
            )
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.filled = false});
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
