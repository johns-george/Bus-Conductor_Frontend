import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';

class ForgotEmailScreen extends ConsumerStatefulWidget {
  const ForgotEmailScreen({super.key});

  @override
  ConsumerState<ForgotEmailScreen> createState() => _ForgotEmailScreenState();
}

class _ForgotEmailScreenState extends ConsumerState<ForgotEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  bool _found = false;
  String? _foundEmail;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.postJson(
        '/auth/forgot-email',
        body: {'phone': _phoneCtrl.text.trim()},
      );

      if (!mounted) return;

      if (response is Map<String, dynamic> && response['found'] == true) {
        setState(() {
          _found = true;
          _foundEmail = response['email']?.toString();
          _loading = false;
        });
      } else {
        setState(() {
          _error = response['message']?.toString() ?? 'No account found with this phone number.';
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Something went wrong. Try again.'; _loading = false; });
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
        child: _found ? _buildSuccess(theme, palette) : _buildForm(theme, palette),
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
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 56,
              color: AppColors.tealStrong,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Forgot your email?',
              style: theme.textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Enter the phone number you signed up with and we'll find your email.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Phone number',
              controller: _phoneCtrl,
              hintText: '98xxxxxxxx',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => Validators.notEmpty(v, field: 'Phone number'),
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
              label: 'Find my email',
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
            Text('Email found!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'An account was found with this phone number.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: AppColors.tealStrong.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, color: AppColors.tealStrong, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _foundEmail ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.midnight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Use this email to sign in or reset your password.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Go to login',
              size: AppButtonSize.lg,
              onPressed: () => context.go('/auth/login'),
            ),
            const SizedBox(height: AppSpacing.md),
            GhostButton(
              label: 'Forgot password?',
              onPressed: () => context.push('/auth/forgot-password'),
            ),
          ],
        ),
      ),
    );
  }
}
