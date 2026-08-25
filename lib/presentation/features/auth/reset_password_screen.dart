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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).resetPassword(
            token: _tokenCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (mounted) setState(() { _success = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Reset failed. Check your token and try again.'; _loading = false; });
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
        child: _success ? _buildSuccess(theme, palette) : _buildForm(theme, palette),
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
              Icons.password_rounded,
              size: 56,
              color: AppColors.tealStrong,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Reset password',
              style: theme.textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Paste the token from your email and choose a new password.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Reset token',
              controller: _tokenCtrl,
              hintText: 'rst_...',
              prefixIcon: Icons.vpn_key_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.notEmpty(v, field: 'Reset token'),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'New password',
              controller: _passwordCtrl,
              hintText: 'At least 6 characters',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: Validators.password,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Confirm password',
              controller: _confirmCtrl,
              hintText: 'Re-enter password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password';
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
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
              label: 'Reset password',
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
            Text('Password reset!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your password has been updated. You can now sign in with your new password.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Go to login',
              size: AppButtonSize.lg,
              onPressed: () => context.go('/auth/login'),
            ),
          ],
        ),
      ),
    );
  }
}
