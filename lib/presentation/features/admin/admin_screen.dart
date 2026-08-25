import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/repository_providers.dart';
import '../auth/auth_controller.dart';

/// Admin dashboard — web-optimized management panel.
/// Shows stats, user list, route/schedule management.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;

    final userName = session?.user.displayName ?? 'Admin';
    final email = session?.user.email ?? '';
    final initials = userName.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.coral, AppColors.coral.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    initials.length >= 2 ? initials.substring(0, 2) : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                        userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadii.rSm,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(bottom: BorderSide(color: palette.border)),
            ),
            child: Row(
              children: [
                _tabButton('Overview', 0),
                _tabButton('Users', 1),
                _tabButton('Routes & Schedules', 2),
                _tabButton('Transactions', 3),
              ],
            ),
          ),
          // Content
          Expanded(
            child: switch (_tab) {
              0 => _OverviewTab(),
              1 => _UsersTab(),
              2 => _RoutesTab(),
              3 => _TransactionsTab(),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.teal : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.tealStrong : palette.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ===== OVERVIEW TAB =====
class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(_statsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        if (stats.isEmpty) return const Center(child: Text('No data'));
        final users = stats['users'] ?? {};
        final tickets = stats['tickets'] ?? {};
        final fleet = stats['fleet'] ?? {};
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Dashboard Overview', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            // Revenue card
            _BigStatCard(
              label: 'Total Revenue',
              value: '₹${(stats['revenue'] ?? 0).toStringAsFixed(0)}',
              icon: Icons.payments_rounded,
              color: AppColors.tealStrong,
            ),
            const SizedBox(height: AppSpacing.md),
            // Stats grid
            Row(
              children: [
                _SmallStat(label: 'Users', value: '${users['total'] ?? 0}', color: AppColors.info),
                const SizedBox(width: AppSpacing.md),
                _SmallStat(label: 'Conductors', value: '${users['conductors'] ?? 0}', color: AppColors.amberStrong),
                const SizedBox(width: AppSpacing.md),
                _SmallStat(label: 'Admins', value: '${users['admins'] ?? 0}', color: AppColors.coral),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _SmallStat(label: 'Total tickets', value: '${tickets['total'] ?? 0}', color: AppColors.tealStrong),
                const SizedBox(width: AppSpacing.md),
                _SmallStat(label: 'Active', value: '${tickets['active'] ?? 0}', color: AppColors.success),
                const SizedBox(width: AppSpacing.md),
                _SmallStat(label: 'Validated', value: '${tickets['validated'] ?? 0}', color: AppColors.info),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _SmallStat(label: 'Buses', value: '${fleet['buses'] ?? 0}', color: AppColors.tealStrong),
                const SizedBox(width: AppSpacing.md),
                _SmallStat(label: 'Routes', value: '${fleet['routes'] ?? 0}', color: AppColors.amberStrong),
                const SizedBox(width: AppSpacing.md),
                _SmallStat(label: 'Schedules', value: '${fleet['schedules'] ?? 0}', color: AppColors.coral),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ===== USERS TAB =====
class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final async = ref.watch(_usersProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('No users'));
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final u = users[i];
            final roleColor = switch (u['role']) {
              'ADMIN' => AppColors.coral,
              'CONDUCTOR' => AppColors.amberStrong,
              _ => AppColors.tealStrong,
            };
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: roleColor.withValues(alpha: 0.15),
                    child: Text(
                      '${(u['full_name'] ?? u['username'] ?? '?').toString()[0].toUpperCase()}',
                      style: TextStyle(color: roleColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${u['full_name'] ?? u['username'] ?? ''}', style: theme.textTheme.titleSmall),
                        Text('${u['email'] ?? ''}', style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: AppRadii.rSm,
                    ),
                    child: Text(
                      '${u['role'] ?? 'USER'}',
                      style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: palette.textMuted),
                    onSelected: (role) => _changeRole(ref, u['id'] as int?, role),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'USER', child: Text('Set as User')),
                      const PopupMenuItem(value: 'CONDUCTOR', child: Text('Set as Conductor')),
                      const PopupMenuItem(value: 'ADMIN', child: Text('Set as Admin')),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _changeRole(WidgetRef ref, int? userId, String role) async {
    if (userId == null) return;
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.putJson('/admin/users/$userId/role', body: {'role': role});
      ref.invalidate(_usersProvider);
      ref.invalidate(_statsProvider);
    } catch (e) {
      // ignore
    }
  }
}

// ===== ROUTES TAB =====
class _RoutesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final async = ref.watch(_schedulesProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (schedules) {
        if (schedules.isEmpty) return const Center(child: Text('No schedules'));
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: schedules.length,
          itemBuilder: (ctx, i) {
            final s = schedules[i];
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.tealSoft,
                      borderRadius: AppRadii.rSm,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${s['start_time']?.toString().substring(0, 5) ?? '--:--'}',
                      style: TextStyle(
                        color: AppColors.tealStrong,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s['bus_name'] ?? ''}', style: theme.textTheme.titleSmall),
                        Text(
                          '${s['route_name'] ?? ''} · Platform ${s['platform'] ?? 'P1'}',
                          style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Days: ${s['days_of_week']?.toString() ?? 'Every day'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.tealStrong,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ===== TRANSACTIONS TAB =====
class _TransactionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final async = ref.watch(_allTxProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (txns) {
        if (txns.isEmpty) return const Center(child: Text('No transactions'));
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: txns.length,
          itemBuilder: (ctx, i) {
            final t = txns[i];
            final isCredit = t['type'] == 'TOPUP' || t['type'] == 'REFUND';
            final tone = switch (t['status']) {
              'SUCCESSFUL' => isCredit ? AppColors.success : AppColors.tealStrong,
              'FAILED' => AppColors.error,
              'PENDING' => AppColors.amberStrong,
              _ => palette.textMuted,
            };
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Icon(
                    isCredit ? Icons.add_rounded : Icons.arrow_outward_rounded,
                    color: tone,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${t['note'] ?? t['type'] ?? ''}', style: theme.textTheme.titleSmall),
                        Text(
                          'User #${t['user_id']} · ${t['payment_method'] ?? ''} · ${t['status'] ?? ''}',
                          style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isCredit ? '+' : '-'}₹${t['amount'] ?? 0}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ===== SHARED WIDGETS =====
class _BigStatCard extends StatelessWidget {
  const _BigStatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadii.rLg,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: AppRadii.rMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ===== PROVIDERS =====
final _statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final raw = await apiClient.getJson('/admin/stats');
    return raw as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
});

final _usersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final raw = await apiClient.getJson('/admin/users');
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
});

final _schedulesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final raw = await apiClient.getJson('/admin/schedules');
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
});

final _allTxProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final raw = await apiClient.getJson('/admin/transactions');
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
});
