import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/repository_providers.dart';
import '../auth/auth_controller.dart';

/// Real QR camera scanner for conductor ticket validation.
/// Opens the device camera, scans a QR code, and validates the ticket.
class ConductorScanScreen extends ConsumerStatefulWidget {
  const ConductorScanScreen({super.key});

  @override
  ConsumerState<ConductorScanScreen> createState() =>
      _ConductorScanScreenState();
}

class _ConductorScanScreenState extends ConsumerState<ConductorScanScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _cameraController;
  StreamSubscription<Object?>? _barcodeSub;
  bool _isProcessing = false;
  bool _hasScanned = false;
  _ScanResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    // Start listening to barcode events
    _barcodeSub = _cameraController.barcodes.listen(_onBarcode);
    // Start the camera
    _cameraController.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraController.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _barcodeSub = _cameraController.barcodes.listen(_onBarcode);
        _cameraController.start();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _barcodeSub?.cancel();
        _barcodeSub = null;
        _cameraController.stop();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeSub?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  void _onBarcode(BarcodeCapture capture) {
    if (_isProcessing || _hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _hasScanned = true;
    _validateToken(barcode.rawValue!);
  }

  Future<void> _validateToken(String token) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    // Pause camera while processing
    await _cameraController.stop();

    try {
      final apiClient = ref.read(apiClientProvider);
      final raw = await apiClient.postJson(
        '/conductor/validate',
        body: {
          'token': token,
          'conductor_id': session.user.id,
        },
      );

      if (mounted) {
        setState(() {
          _result = _ScanResult.fromMap(raw as Map<String, dynamic>);
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = _ScanResult(
            success: false,
            message: 'Network error: $e',
            status: 'ERROR',
          );
          _isProcessing = false;
        });
      }
    }
  }

  void _scanAgain() {
    setState(() {
      _hasScanned = false;
      _result = null;
      _isProcessing = false;
    });
    _barcodeSub = _cameraController.barcodes.listen(_onBarcode);
    _cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Scan Ticket QR',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Flash toggle
          ValueListenableBuilder(
            valueListenable: _cameraController,
            builder: (context, state, _) {
              if (!state.isInitialized || state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: Colors.white,
                ),
                onPressed: () => _cameraController.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera view
          if (_result == null)
            MobileScanner(
              controller: _cameraController,
            ),

          // Scan overlay (drawn on top of camera)
          if (_result == null && !_isProcessing)
            _buildScanOverlay(context),

          // Scanning indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.tealStrong),
                    SizedBox(height: 16),
                    Text(
                      'Validating ticket...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Result card
          if (_result != null) _buildResultOverlay(context),

          // Bottom hint
          if (_result == null && !_isProcessing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white70,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Point camera at passenger\'s QR code',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.keyboard_rounded, size: 18),
                        label: const Text('Enter ticket ID manually'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.tealStrong,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          children: [
            // Semi-transparent border
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.tealStrong.withValues(alpha: 0.6),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            // Corner accents
            Positioned(
              top: -1,
              left: -1,
              child: _cornerAccent(isTopLeft: true),
            ),
            Positioned(
              top: -1,
              right: -1,
              child: _cornerAccent(isTopRight: true),
            ),
            Positioned(
              bottom: -1,
              left: -1,
              child: _cornerAccent(isBottomLeft: true),
            ),
            Positioned(
              bottom: -1,
              right: -1,
              child: _cornerAccent(isBottomRight: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cornerAccent({
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _CornerPainter(
        isTopLeft: isTopLeft,
        isTopRight: isTopRight,
        isBottomLeft: isBottomLeft,
        isBottomRight: isBottomRight,
      ),
    );
  }

  Widget _buildResultOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final isSuccess = _result!.success;
    final color = isSuccess ? AppColors.success : AppColors.error;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isSuccess ? 'Ticket Validated!' : 'Validation Failed',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _result!.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              if (_result!.passenger != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadii.rMd,
                  ),
                  child: Column(
                    children: [
                      _resultRow(theme, 'Passenger',
                          '${_result!.passenger!['name'] ?? 'Unknown'}'),
                      if (_result!.ticket != null) ...[
                        const SizedBox(height: 4),
                        _resultRow(theme, 'Ticket ID',
                            '#${_result!.ticket!['id']}'),
                        _resultRow(theme, 'Price',
                            '₹${_result!.ticket!['price'] ?? 0}'),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _scanAgain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealStrong,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Scan Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.extension<AppPalette>()!.surfaces.textMuted,
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

class _ScanResult {
  final bool success;
  final String message;
  final String status;
  final Map<String, dynamic>? ticket;
  final Map<String, dynamic>? passenger;

  _ScanResult({
    required this.success,
    required this.message,
    required this.status,
    this.ticket,
    this.passenger,
  });

  factory _ScanResult.fromMap(Map<String, dynamic> m) {
    return _ScanResult(
      success: m['success'] == true,
      message: (m['message'] ?? 'Unknown').toString(),
      status: (m['status'] ?? 'UNKNOWN').toString(),
      ticket: m['ticket'] is Map
          ? Map<String, dynamic>.from(m['ticket'] as Map)
          : null,
      passenger: m['passenger'] is Map
          ? Map<String, dynamic>.from(m['passenger'] as Map)
          : null,
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.isTopLeft,
    required this.isTopRight,
    required this.isBottomLeft,
    required this.isBottomRight,
  });

  final bool isTopLeft, isTopRight, isBottomLeft, isBottomRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.tealStrong
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    const len = 20.0;

    if (isTopLeft) {
      path.moveTo(0, len);
      path.lineTo(0, 0);
      path.lineTo(len, 0);
    } else if (isTopRight) {
      path.moveTo(size.width - len, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, len);
    } else if (isBottomLeft) {
      path.moveTo(0, size.height - len);
      path.lineTo(0, size.height);
      path.lineTo(len, size.height);
    } else if (isBottomRight) {
      path.moveTo(size.width - len, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - len);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
