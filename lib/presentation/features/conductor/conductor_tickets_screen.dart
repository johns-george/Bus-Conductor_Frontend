import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/repository_providers.dart';
import '../auth/auth_controller.dart';

class ConductorTicketsScreen extends ConsumerStatefulWidget {
  const ConductorTicketsScreen({super.key});

  @override
  ConsumerState<ConductorTicketsScreen> createState() =>
      _ConductorTicketsScreenState();
}

class _ConductorTicketsScreenState
    extends ConsumerState<ConductorTicketsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;
    final conductorId = session?.user.id ?? '';

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Validated Tickets'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetch(conductorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined, size: 64, color: palette.textMuted),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No validated tickets yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tickets you validate will appear here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: tickets.length,
            itemBuilder: (ctx, i) {
              final t = tickets[i];
              final status = (t['status'] ?? 'UNKNOWN').toString();
              final tone = switch (status) {
                'VALIDATED' => AppColors.success,
                'CANCELLED' => AppColors.error,
                'EXPIRED' => AppColors.amberStrong,
                _ => palette.textMuted,
              };

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: AppRadii.rLg,
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.12),
                            borderRadius: AppRadii.rSm,
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: tone,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Ticket #${t['id']}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _detailRow(theme, palette, 'Passenger',
                        '${t['passenger_name'] ?? 'Unknown'}'),
                    _detailRow(
                      theme,
                      palette,
                      'Price',
                      '₹${t['price'] ?? 0}',
                    ),
                    _detailRow(
                      theme,
                      palette,
                      'Validated at',
                      _formatTime(t['validated_at']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetch(String conductorId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final raw = await apiClient.getJson(
        '/conductor/validated-tickets/$conductorId',
      );
      if (raw is! List) return [];
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '--';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final mon = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][dt.month];
      return '$mon ${dt.day}, $h:$m';
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _detailRow(
      ThemeData theme, AppSurfaces palette, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
