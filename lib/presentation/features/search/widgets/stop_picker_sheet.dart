import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/stop.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeleton.dart';
import '../../../widgets/inputs/search_text_field.dart';
import '../search_controller.dart';

/// Full-height bottom sheet for selecting a stop. Mirrors the interaction
/// language of modern transit apps: debounced autocomplete, popular chips,
/// and room to grow (nearby, saved, recent) later.
class StopPickerSheet extends ConsumerStatefulWidget {
  const StopPickerSheet({
    super.key,
    required this.title,
    required this.hint,
    this.excludeStopId,
  });

  final String title;
  final String hint;
  final String? excludeStopId;

  static Future<Stop?> show(
    BuildContext context, {
    required String title,
    required String hint,
    String? excludeStopId,
  }) {
    return showModalBottomSheet<Stop>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => StopPickerSheet(
        title: title,
        hint: hint,
        excludeStopId: excludeStopId,
      ),
    );
  }

  @override
  ConsumerState<StopPickerSheet> createState() => _StopPickerSheetState();
}

class _StopPickerSheetState extends ConsumerState<StopPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final mq = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(AppIcons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SearchTextField(
                  controller: _controller,
                  hint: widget.hint,
                  onChanged: _onChanged,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _query.isEmpty
                    ? _PopularPane(scrollController: scrollController)
                    : _ResultsPane(
                        query: _query,
                        scrollController: scrollController,
                        excludeStopId: widget.excludeStopId,
                        onPick: (stop) => Navigator.of(context).pop(stop),
                      ),
              ),
              Container(height: 1, color: palette.border),
              const _QuickActionsBar(),
            ],
          ),
        );
      },
    );
  }
}

class _PopularPane extends ConsumerWidget {
  const _PopularPane({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final popular = ref.watch(popularStopsProvider);

    return popular.when(
      loading: () => ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const AppShimmer(
          child: SkeletonBlock(height: 56, radius: AppRadii.md),
        ),
      ),
      error: (err, _) => ErrorStateView(
        message: 'Could not load stops — $err',
        onRetry: () => ref.invalidate(popularStopsProvider),
      ),
      data: (stops) {
        if (stops.isEmpty) {
          return const EmptyState(
            title: 'No suggestions yet',
            message:              'Start typing to search for stops.',
            icon: AppIcons.search,
          );
        }
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl2,
          ),
          children: [
            Text(
              stops.length > 10 ? 'All stops (${stops.length})' : 'Nearby stops',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...stops.map(
              (s) => _StopTile(
                stop: s,
                onTap: () => Navigator.of(context).pop(s),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultsPane extends ConsumerWidget {
  const _ResultsPane({
    required this.query,
    required this.scrollController,
    required this.onPick,
    this.excludeStopId,
  });

  final String query;
  final ScrollController scrollController;
  final ValueChanged<Stop> onPick;
  final String? excludeStopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(stopSuggestionsProvider(query));
    return suggestions.when(
      loading: () => ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const AppShimmer(
          child: SkeletonBlock(height: 56, radius: AppRadii.md),
        ),
      ),
      error: (err, _) => ErrorStateView(
        message: 'Search failed — $err',
        onRetry: () => ref.invalidate(stopSuggestionsProvider(query)),
      ),
      data: (stops) {
        final filtered = excludeStopId == null
            ? stops
            : stops.where((s) => s.id != excludeStopId).toList();
        if (filtered.isEmpty) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl2,
            ),
            children: [
              EmptyState(
                title: 'No matches for "$query"',
                message: 'Try a nearby landmark, city, or area.',
                icon: AppIcons.search,
              ),
              const SizedBox(height: AppSpacing.md),
              _CustomStopTile(
                query: query,
                onTap: () {
                  // Create a custom stop with the typed query
                  final customStop = Stop(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: query,
                    city: 'Custom location',
                    area: null,
                    isPopular: false,
                  );
                  onPick(customStop);
                },
              ),
            ],
          );
        }
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl2,
          ),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (_, i) => _StopTile(
            stop: filtered[i],
            highlight: query,
            onTap: () => onPick(filtered[i]),
          ),
        );
      },
    );
  }
}

class _CustomStopTile extends StatelessWidget {
  const _CustomStopTile({required this.query, required this.onTap});
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.rMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.rMd,
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadii.rSm,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use "$query" as custom location',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.primary,
                          ),
                    ),
                    Text(
                      'Continue with this location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({required this.stop, required this.onTap, this.highlight});
  final Stop stop;
  final VoidCallback onTap;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.rMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadii.rSm,
                ),
                child: Icon(
                  AppIcons.pinDestination,
                  size: 18,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      [stop.area, stop.city]
                          .whereType<String>()
                          .join(' \u00B7 '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.myLocation,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Use current location',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: palette.textSecondary),
            ),
          ),
          Text(
            'Coming soon',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}
