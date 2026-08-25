import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../providers/repository_providers.dart';
import 'auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  bool _obscure = true;
  bool _acceptedTerms = false;
  String _role = 'USER';

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_refreshFormState);
    _emailCtrl.addListener(_refreshFormState);
    _passwordCtrl.addListener(_refreshFormState);
    _mobileCtrl.addListener(_refreshFormState);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_refreshFormState);
    _emailCtrl.removeListener(_refreshFormState);
    _passwordCtrl.removeListener(_refreshFormState);
    _mobileCtrl.removeListener(_refreshFormState);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _nameCtrl.text.trim().isNotEmpty &&
        _emailCtrl.text.trim().isNotEmpty &&
        _mobileCtrl.text.trim().isNotEmpty &&
        _passwordCtrl.text.trim().isNotEmpty &&
        _acceptedTerms;
  }

  void _refreshFormState() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_isFormValid()) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authControllerProvider.notifier).signupWithEmail(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          mobileNumber: _mobileCtrl.text.trim(),
          role: _role,
        );
    if (!mounted) return;
    if (ok) _goAfterAuth();
  }

  String? get _returnTo =>
      GoRouterState.of(context).uri.queryParameters['returnTo'];

  void _goAfterAuth() {
    final returnTo = _returnTo;
    if (returnTo != null && returnTo.isNotEmpty) {
      context.go(returnTo);
      return;
    }
    // Route based on role — read directly from repo (synchronous)
    final session = ref.read(authRepositoryProvider).currentSession;
    final role = session?.user.role?.toUpperCase();
    if (role == 'ADMIN') {
      context.go('/admin');
    } else if (role == 'CONDUCTOR') {
      context.go('/conductor');
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final form = ref.watch(authControllerProvider);

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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
            children: [
              Text('Create your account', style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'A few seconds and you\u2019re set for smoother commutes.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'Full name *',
                controller: _nameCtrl,
                hintText: 'Alex Kumar',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) => Validators.notEmpty(v, field: 'Full name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email *',
                controller: _emailCtrl,
                hintText: 'you@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Mobile number *',
                controller: _mobileCtrl,
                hintText: '+1234567890',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: (v) =>
                    Validators.notEmpty(v, field: 'Mobile number'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _RoleDropdown(
                value: _role,
                onChanged: (v) => setState(() => _role = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Password *',
                controller: _passwordCtrl,
                hintText: 'At least 6 characters',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                validator: Validators.password,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'I agree to the Terms of Service and Privacy Policy.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
              if (form.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: AppRadii.rMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.error,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          form.errorMessage!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_acceptedTerms) ...[
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Create account',
                  size: AppButtonSize.lg,
                  loading: form.isSubmitting,
                  onPressed:
                      (form.isSubmitting || !_isFormValid()) ? null : _submit,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  GhostButton(
                    label: 'Sign in',
                    onPressed: () {
                      final returnTo = _returnTo;
                      context.pushReplacement(
                        returnTo == null || returnTo.isEmpty
                            ? AppRoutes.login
                            : '${AppRoutes.login}?returnTo=${Uri.encodeComponent(returnTo)}',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a *',
          style: theme.textTheme.labelLarge?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadii.rMd,
            border: Border.all(color: palette.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(AppIcons.chevronDown, size: 18),
              items: const [
                DropdownMenuItem(
                  value: 'USER',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Passenger'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'CONDUCTOR',
                  child: Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Bus Conductor'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'ADMIN',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Admin'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
