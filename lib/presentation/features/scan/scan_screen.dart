import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/buttons/primary_button.dart';
import '../auth/auth_controller.dart';

/// Mock QR scanner — the real camera feed lands in Phase 4 behind
/// `package:mobile_scanner`. This screen makes the happy path feel real by
/// animating a "scanning" state and resolving to either a boarding prompt or
/// a ticket validation toast after a short delay.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  bool _scanning = false;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _simulateScan() async {
    setState(() {
      _scanning = true;
      _lastResult = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final tickets =
        await ref.read(ticketRepositoryProvider).byUser(
              ref.read(authSessionProvider).valueOrNull?.user.id ?? 'u_alex',
            );
    if (!mounted) return;

    // Pick a random active ticket to "scan", else show a boarding prompt.
    final active = tickets
        .where((t) => t.status.toString().contains('active'))
        .toList();
    if (active.isNotEmpty) {
      final picked = active[Random().nextInt(active.length)];
      setState(() {
        _scanning = false;
        _lastResult = 'Ticket ${picked.id.substring(3)}';
      });
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      context.push('/ticket/${picked.id}');
    } else {
      setState(() {
        _scanning = false;
        _lastResult = 'No active ticket found on this account.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.close, color: Colors.white),
                    onPressed: () => context.go('/home'),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan to board',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Align the ticket QR inside the frame',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_off_rounded,
                        color: Colors.white,),
                    onPressed: () {},
                    tooltip: 'Torch',
                  ),
                ],
              ),
            ),
            Expanded(child: _ScanViewport(controller: _scanCtrl)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (_lastResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: AppRadii.rMd,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 20,),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _lastResult!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  PrimaryButton(
                    label: _scanning ? 'Scanning...' : 'Simulate scan',
                    icon: AppIcons.qr,
                    size: AppButtonSize.lg,
                    loading: _scanning,
                    onPressed: _scanning ? null : _simulateScan,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Live camera scanning arrives in Phase 4.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
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

class _ScanViewport extends StatelessWidget {
  const _ScanViewport({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight) * 0.7;
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: AppRadii.rLg,
                ),
                child: CustomPaint(painter: _CornerPainter()),
              ),
              // Animated scanning line.
              AnimatedBuilder(
                animation: controller,
                builder: (_, __) {
                  final t = controller.value;
                  return Positioned(
                    top: 24 + (size - 48) * t,
                    child: Container(
                      width: size - 40,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.teal.withValues(alpha: 0),
                            AppColors.teal,
                            AppColors.teal.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadii.rPill,
                  ),
                  child: const Text(
                    'Hold steady',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const armLen = 28.0;
    // Top-left
    canvas
      ..drawLine(const Offset(0, armLen), const Offset(0, 0), paint)
      ..drawLine(const Offset(0, 0), const Offset(armLen, 0), paint)
      // Top-right
      ..drawLine(
          Offset(size.width - armLen, 0), Offset(size.width, 0), paint,)
      ..drawLine(
          Offset(size.width, 0), Offset(size.width, armLen), paint,)
      // Bottom-left
      ..drawLine(
          Offset(0, size.height - armLen), Offset(0, size.height), paint,)
      ..drawLine(
          Offset(0, size.height), Offset(armLen, size.height), paint,)
      // Bottom-right
      ..drawLine(Offset(size.width - armLen, size.height),
          Offset(size.width, size.height), paint,)
      ..drawLine(Offset(size.width, size.height - armLen),
          Offset(size.width, size.height), paint,);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
