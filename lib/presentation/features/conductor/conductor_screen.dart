import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/ticket.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/buttons/primary_button.dart';
import '../auth/auth_controller.dart';

/// Conductor-facing screen for validating passenger QR tickets.
/// Shows a text field to paste/enter the QR token, validates it,
/// and displays the result with passenger + ticket details.
class ConductorScreen extends ConsumerStatefulWidget {
  const ConductorScreen({super.key});

  @override
  ConsumerState<ConductorScreen> createState() => _ConductorScreenState();
}

class _ConductorScreenState extends ConsumerState<ConductorScreen> {
  final _tokenController = TextEditingController();
  final _manualIdController = TextEditingController();
  bool _isProcessing = false;
  _ValidationResult? _lastResult;
  int _validatedToday = 0;
  int _rejectedToday = 0;

  @override
  void dispose() {
    _tokenController.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;

    final userName = session?.user.displayName ?? 'Conductor';
    final email = session?.user.email ?? '';
    final initials = userName.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Conductor Panel'),
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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealStrong, AppColors.tealStrong.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadii.rLg,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    initials.length >= 2 ? initials.substring(0, 2) : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
                      Icon(Icons.badge_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'CONDUCTOR',
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
          const SizedBox(height: AppSpacing.xl),
          // Stats row
          Row(
            children: [
              _StatCard(
                label: 'Validated',
                count: _validatedToday,
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatCard(
                label: 'Rejected',
                count: _rejectedToday,
                icon: Icons.cancel_rounded,
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Big scan button
          GestureDetector(
            onTap: () => context.push('/conductor/scan'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.tealStrong],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadii.rLg,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // My validated tickets link
          GestureDetector(
            onTap: () => context.push('/conductor/tickets'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.tealStrong, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'My Validated Tickets',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.tealStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: palette.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Token input
          Text('Enter ticket QR token', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Paste the QR code data or enter the ticket ID manually.',
            style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _tokenController,
            decoration: InputDecoration(
              hintText: 'Paste QR token here...',
              prefixIcon: const Icon(Icons.qr_code_2_rounded),
              suffixIcon: _tokenController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _tokenController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _validate(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Manual ticket ID entry
          Text('Or enter ticket ID', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualIdController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 42',
                    prefixIcon: Icon(Icons.confirmation_number_rounded),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: _isProcessing ? null : _validateManual,
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Look up ticket',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Validate button
          PrimaryButton(
            label: _isProcessing ? 'Validating...' : 'Validate ticket',
            icon: Icons.verified_rounded,
            size: AppButtonSize.lg,
            loading: _isProcessing,
            onPressed: _isProcessing ? null : _validate,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Result card
          if (_lastResult != null) _ResultCard(result: _lastResult!),
        ],
      ),
    );
  }

  Future<void> _validate() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a QR token or ticket ID'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      // Send conductor_id — backend accepts numeric ID or username
      final raw = await apiClient.postJson(
        '/conductor/validate',
        body: {
          'token': token,
          'conductor_id': session.user.id,
        },
      );

      final result = _ValidationResult.fromMap(raw as Map<String, dynamic>);

      setState(() {
        _lastResult = result;
        if (result.success) {
          _validatedToday++;
        } else {
          _rejectedToday++;
        }
      });
    } catch (e) {
      setState(() {
        _lastResult = _ValidationResult(
          success: false,
          message: 'Network error: $e',
          status: 'ERROR',
        );
        _rejectedToday++;
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _validateManual() async {
    final idText = _manualIdController.text.trim();
    if (idText.isEmpty) return;

    final ticketId = int.tryParse(idText);
    if (ticketId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid ticket number'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastResult = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final raw = await apiClient.postJson(
        '/conductor/validate-by-id',
        body: {
          'ticket_id': ticketId,
          'conductor_id': session.user.id,
        },
      );
      final result = _ValidationResult.fromMap(raw as Map<String, dynamic>);
      setState(() {
        _lastResult = result;
        if (result.success) _validatedToday++;
        else _rejectedToday++;
      });
    } catch (e) {
      setState(() {
        _lastResult = _ValidationResult(
          success: false,
          message: 'Network error: $e',
          status: 'ERROR',
        );
        _rejectedToday++;
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _ValidationResult {
  final bool success;
  final String message;
  final String status;
  final String? validatedBy;
  final Map<String, dynamic>? ticket;
  final Map<String, dynamic>? passenger;

  _ValidationResult({
    required this.success,
    required this.message,
    required this.status,
    this.validatedBy,
    this.ticket,
    this.passenger,
  });

  factory _ValidationResult.fromMap(Map<String, dynamic> m) {
    return _ValidationResult(
      success: m['success'] == true,
      message: (m['message'] ?? 'Unknown result').toString(),
      status: (m['status'] ?? 'UNKNOWN').toString(),
      validatedBy: m['validated_by']?.toString(),
      ticket: m['ticket'] is Map ? Map<String, dynamic>.from(m['ticket'] as Map) : null,
      passenger: m['passenger'] is Map ? Map<String, dynamic>.from(m['passenger'] as Map) : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadii.rMd,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final _ValidationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

    final Color tone = result.success ? AppColors.success : AppColors.error;
    final IconData icon = result.success
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: AppRadii.rLg,
        border: Border.all(color: tone.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tone, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.success ? 'Ticket Validated' : 'Validation Failed',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tone,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      result.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.ticket != null) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: palette.border),
            const SizedBox(height: AppSpacing.sm),
            _detailRow(theme, palette, 'Ticket ID', '#${result.ticket!['id']}'),
            _detailRow(theme, palette, 'Status', '${result.ticket!['status'] ?? ''}'),
            _detailRow(theme, palette, 'Price', '₹${result.ticket!['price'] ?? 0}'),
            if (result.ticket!['expires_at'] != null)
              _detailRow(theme, palette, 'Expires', '${result.ticket!['expires_at']}'),
          ],
          if (result.passenger != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _detailRow(theme, palette, 'Passenger', '${result.passenger!['name'] ?? 'Unknown'}'),
          ],
          if (result.validatedBy != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _detailRow(theme, palette, 'Validated by', result.validatedBy!),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(ThemeData theme, AppSurfaces palette, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
