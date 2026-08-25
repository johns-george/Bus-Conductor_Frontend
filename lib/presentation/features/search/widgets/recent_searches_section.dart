import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../domain/entities/saved_route.dart';
import '../../../providers/repository_providers.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/skeleton.dart';
import '../../search/search_controller.dart';

class RecentSearchesSection extends ConsumerWidget {
  const RecentSearchesSection({super.key, required this.onSelect});
  final void Function(RecentSearch r) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentSearchesProvider);
    return async.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'Recent searches'),
          AppShimmer(child: SkeletonBlock(height: 76, radius: AppRadii.md)),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'Recent searches',
              action: TextButton(
                onPressed: () async {
                  await ref.read(routeRepositoryProvider).clearRecentSearches();
                  ref.invalidate(recentSearchesProvider);
                },
                child: const Text('Clear'),
              ),
            ),
            ...items.take(5).map(
                  (r) => _RecentTile(item: r, onTap: () => onSelect(r)),
                ),
          ],
        );
      },
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item, required this.onTap});
  final RecentSearch item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        child: InkWell(
          borderRadius: AppRadii.rMd,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md,),
            decoration: BoxDecoration(
              borderRadius: AppRadii.rMd,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadii.rSm,
                  ),
                  child: Icon(AppIcons.history,
                      size: 16, color: palette.textSecondary,),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.from.name} \u2192 ${item.to.name}',
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.from.city} \u00B7 ${item.to.city}',
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
                Icon(AppIcons.chevronRight,
                    size: 18, color: palette.textMuted,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PopularSuggestionsSection extends ConsumerWidget {
  const PopularSuggestionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(popularStopsProvider);

    return async.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'Popular near you'),
          AppShimmer(child: SkeletonBlock(height: 44, radius: AppRadii.pill)),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stops) {
        if (stops.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Popular near you',
              subtitle: 'Tap a stop to start a search',
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: stops.take(8).map((s) {
                return Material(
                  color: palette.surface,
                  borderRadius: AppRadii.rPill,
                  child: InkWell(
                    borderRadius: AppRadii.rPill,
                    onTap: () => ref
                        .read(searchFormProvider.notifier)
                        .setFrom(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm,),
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.rPill,
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.pinDestination,
                              size: 14, color: scheme.primary,),
                          const SizedBox(width: 6),
                          Text(
                            s.name,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
