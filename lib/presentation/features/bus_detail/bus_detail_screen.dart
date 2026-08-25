import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';
import '../../../domain/entities/bus.dart';
import '../../../domain/entities/route.dart';
import '../../../domain/entities/stop.dart';
import '../../widgets/badges/status_badge.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/skeleton.dart';
import '../auth/auth_controller.dart';
import '../booking/booking_controller.dart';
import 'bus_detail_controller.dart';

/// Detailed view for a single bus — live status, occupancy, amenities and
/// a strong CTA to continue into the booking flow. When [route] is provided
/// (the common path: user arrived from route detail) the CTA starts a
/// booking with full context; otherwise it falls back to a search nudge.
class BusDetailScreen extends ConsumerWidget {
  const BusDetailScreen({
    super.key,
    required this.busId,
    this.initialDetail,
    this.route,
    this.from,
    this.to,
  });

  final String busId;
  final BusDetail? initialDetail;
  final BusRoute? route;
  final Stop? from;
  final Stop? to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final async = initialDetail != null
        ? AsyncValue<BusDetail?>.data(initialDetail!)
        : ref.watch(busDetailByIdProvider(busId));

    return Scaffold(
      backgroundColor: palette.background,
      body: async.when(
        loading: () => const _Loading(),
        error: (e, _) => _Error(message: '$e'),
        data: (detail) {
          if (detail == null) {
            return const _Error(message: 'This bus is no longer in service.');
          }
          return _BusDetailBody(
            detail: detail,
            route: route,
            from: from,
            to: to,
          );
        },
      ),
    );
  }
}

class _BusDetailBody extends ConsumerWidget {
  const _BusDetailBody({
    required this.detail,
    this.route,
    this.from,
    this.to,
  });
  final BusDetail detail;
  final BusRoute? route;
  final Stop? from;
  final Stop? to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final canBook = route != null && from != null && to != null;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: AppColors.midnight,
          foregroundColor: Colors.white,
          expandedHeight: 220,
          leading: IconButton(
            icon: const Icon(AppIcons.back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              tooltip: 'Share',
              onPressed: () {},
              icon: const Icon(Icons.share_outlined, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _BusHero(detail: detail),
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
              _LiveStatusCard(detail: detail),
              const SizedBox(height: AppSpacing.lg),
              _ScheduleCard(detail: detail),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Amenities',
                subtitle: 'Comfort features on this service',
              ),
              _Amenities(type: detail.bus.type),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Fare & policies',
                subtitle: 'What to expect on board',
              ),
              _PolicyCard(palette: palette, theme: theme),
              const SizedBox(height: AppSpacing.xl2),
              PrimaryButton(
                label: 'Book Ticket',
                icon: AppIcons.ticket,
                size: AppButtonSize.lg,
                onPressed: () async {
                  if (!canBook) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pick this bus from a route to continue booking.',
                        ),
                      ),
                    );
                    return;
                  }
                  final sessionAsync = ref.read(authSessionProvider);
                  final session = sessionAsync.valueOrNull;
                  if (sessionAsync is AsyncLoading) {
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
                  ref.read(bookingControllerProvider.notifier).start(
                        route: route!,
                        from: from!,
                        to: to!,
                        bus: detail,
                      );
                  if (!context.mounted) return;
                  context.push('/booking/passenger');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Share ride details',
                icon: Icons.share_outlined,
                size: AppButtonSize.lg,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Live location & payment integrations arrive with backend hookup.',
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

class _BusHero extends StatelessWidget {
  const _BusHero({required this.detail});
  final BusDetail detail;

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
          right: -60,
          top: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withValues(alpha: 0.12),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: AppRadii.rPill,
                    ),
                    child: Text(
                      detail.bus.type.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  if (detail.isLive) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const _LiveDot(),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                detail.bus.number,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.business_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      detail.bus.operatorName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.35, end: 1).animate(_ctrl),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'LIVE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
        ),
      ],
    );
  }
}

class _LiveStatusCard extends StatelessWidget {
  const _LiveStatusCard({required this.detail});
  final BusDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bus Info', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.place_outlined,
                  label: 'Platform',
                  value: detail.platform ?? '—',
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: palette.border,
              ),
              Expanded(
                child: _MiniMetric(
                  icon: AppIcons.clock,
                  label: 'Departs',
                  value: DateFormatting.time(detail.departureAt),
                  helper: DateFormatting.relativeTime(detail.departureAt),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: palette.border,
              ),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.flag_outlined,
                  label: 'Arrives',
                  value: DateFormatting.time(detail.arrivalAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
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
      children: [
        Icon(icon, size: 18, color: palette.textMuted),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textMuted,
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.detail});
  final BusDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final travel = DateFormatting.durationShort(detail.travelDuration);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Departs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatting.time(detail.departureAt),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.tealSoft,
                      borderRadius: AppRadii.rPill,
                    ),
                    child: Text(
                      travel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.tealStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 90,
                    height: 2,
                    color: palette.border,
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    AppIcons.bus,
                    size: 18,
                    color: palette.textMuted,
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Arrives',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatting.time(detail.arrivalAt),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Amenities extends StatelessWidget {
  const _Amenities({required this.type});
  final BusType type;

  List<_Amenity> _amenitiesFor(BusType type) {
    final common = [
      const _Amenity(icon: Icons.usb_rounded, label: 'USB ports'),
      const _Amenity(icon: Icons.gps_fixed_rounded, label: 'Live GPS'),
    ];
    return switch (type) {
      BusType.acSeater => [
          const _Amenity(icon: Icons.ac_unit_rounded, label: 'Air conditioned'),
          const _Amenity(
              icon: Icons.event_seat_rounded, label: 'Reclining seats'),
          ...common,
        ],
      BusType.nonAcSeater => [
          const _Amenity(
              icon: Icons.event_seat_rounded, label: 'Cushioned seats'),
          const _Amenity(icon: Icons.air_rounded, label: 'Ventilated'),
          ...common,
        ],
      BusType.acSleeper => [
          const _Amenity(icon: Icons.ac_unit_rounded, label: 'AC sleeper'),
          const _Amenity(icon: Icons.bed_rounded, label: 'Flat berths'),
          const _Amenity(
              icon: Icons.curtains_rounded, label: 'Privacy curtains'),
          ...common,
        ],
      BusType.volvo => [
          const _Amenity(icon: Icons.ac_unit_rounded, label: 'Climate control'),
          const _Amenity(
              icon: Icons.event_seat_rounded, label: 'Premium seats'),
          const _Amenity(icon: Icons.wifi_rounded, label: 'On-board Wi-Fi'),
          ...common,
        ],
      BusType.electric => [
          const _Amenity(icon: Icons.bolt_rounded, label: 'Zero emission'),
          const _Amenity(icon: Icons.ac_unit_rounded, label: 'Air conditioned'),
          ...common,
        ],
      BusType.miniBus => [
          const _Amenity(
              icon: Icons.event_seat_rounded, label: 'Compact seating'),
          const _Amenity(icon: Icons.air_rounded, label: 'Ventilated'),
          ...common,
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = _amenitiesFor(type);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((a) => _AmenityChip(amenity: a)).toList(),
    );
  }
}

class _Amenity {
  const _Amenity({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.amenity});
  final _Amenity amenity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(amenity.icon, size: 16, color: AppColors.tealStrong),
          const SizedBox(width: 6),
          Text(amenity.label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.palette, required this.theme});
  final AppSurfaces palette;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Cancellation', 'Free until 1 hour before departure'),
      ('Luggage', '1 cabin + 1 check-in bag per passenger'),
      ('Boarding', 'Arrive 10 minutes before scheduled departure'),
      ('Payment', 'UPI, cards, wallet, or on-board cash'),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      rows[i].$1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1) Divider(color: palette.border, height: 1),
          ],
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(height: 80),
          AppShimmer(child: SkeletonBlock(height: 180, radius: AppRadii.md)),
          SizedBox(height: AppSpacing.md),
          AppShimmer(child: SkeletonBlock(height: 120, radius: AppRadii.md)),
          SizedBox(height: AppSpacing.md),
          AppShimmer(child: SkeletonBlock(height: 240, radius: AppRadii.md)),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message});
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
              title: 'Bus unavailable',
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
