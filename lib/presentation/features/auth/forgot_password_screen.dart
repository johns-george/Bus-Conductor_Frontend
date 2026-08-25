import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: _emailCtrl.text.trim());
      if (mounted) setState(() { _sent = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to send reset instructions. Try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

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
        child: _sent ? _buildSuccess(theme, palette) : _buildForm(theme, palette),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, AppSurfaces palette) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Icon(
              Icons.lock_reset_rounded,
              size: 56,
              color: AppColors.tealStrong,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Forgot password?',
              style: theme.textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "No worries. Enter the email address you used to sign up and we'll send you a reset token.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Email',
              controller: _emailCtrl,
              hintText: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: Validators.email,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: AppRadii.rMd,
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.error, color: AppColors.error, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(_error!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Send reset token',
              size: AppButtonSize.lg,
              loading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(ThemeData theme, AppSurfaces palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Check your email', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'We sent a password reset link to ${_emailCtrl.text.trim()}. Check your inbox and use the token to set a new password.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadii.rMd,
              ),
              child: Text(
                '💡 Tip: In development mode, the reset token is printed in the backend terminal logs.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Reset password',
              size: AppButtonSize.lg,
              onPressed: () => context.push('/auth/reset-password'),
            ),
            const SizedBox(height: AppSpacing.md),
            GhostButton(
              label: 'Back to login',
              onPressed: () => context.go('/auth/login'),
            ),
          ],
        ),
      ),
    );
  }
}
