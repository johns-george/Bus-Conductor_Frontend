import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import 'auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(_otpLength, (_) => FocusNode());
  Timer? _timer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != _otpLength) return;
    final ok = await ref.read(authControllerProvider.notifier).verifyOtp(_code);
    if (!mounted) return;
    if (ok) _goAfterAuth();
  }

  String? get _returnTo =>
      GoRouterState.of(context).uri.queryParameters['returnTo'];

  void _goAfterAuth() {
    final returnTo = _returnTo;
    context
        .go(returnTo == null || returnTo.isEmpty ? AppRoutes.home : returnTo);
  }

  Future<void> _resend() async {
    final form = ref.read(authControllerProvider);
    if (form.pendingPhone == null || form.pendingCountry == null) return;
    final ok = await ref.read(authControllerProvider.notifier).requestOtp(
          name: form.pendingName ?? 'Traveller',
          phone: form.pendingPhone!,
          country: form.pendingCountry!,
        );
    if (!mounted) return;
    if (ok) {
      for (final c in _controllers) {
        c.clear();
      }
      _nodes.first.requestFocus();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final form = ref.watch(authControllerProvider);
    final phoneLabel = form.pendingPhone != null
        ? '${form.pendingCountry ?? ''} ${form.pendingPhone!}'.trim()
        : 'your number';

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter verification code',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'We sent a 6-digit code to $phoneLabel. Enter it below to continue.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _otpLength,
                  (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _nodes[i],
                    isLast: i == _otpLength - 1,
                    onChanged: (v) {
                      if (v.length == 1 && i < _otpLength - 1) {
                        _nodes[i + 1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _nodes[i - 1].requestFocus();
                      }
                      if (_code.length == _otpLength) {
                        _verify();
                      }
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (form.errorMessage != null)
                Text(
                  form.errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _secondsLeft > 0
                        ? 'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}'
                        : "Didn't get it?",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  if (_secondsLeft <= 0)
                    GhostButton(
                      label: 'Resend',
                      onPressed: _resend,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                'For demo, the code is 123456.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Verify',
                size: AppButtonSize.lg,
                loading: form.isSubmitting,
                onPressed: _code.length == _otpLength && !form.isSubmitting
                    ? _verify
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.isLast,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final hasValue = controller.text.isNotEmpty;
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: hasValue ? palette.surface : palette.surfaceMuted,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: AppRadii.rMd,
            borderSide: BorderSide(color: palette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.rMd,
            borderSide: BorderSide(
              color: hasValue ? AppColors.teal : palette.border,
              width: hasValue ? 1.5 : 1,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadii.rMd,
            borderSide: BorderSide(color: AppColors.teal, width: 1.8),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
