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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _emailForm = GlobalKey<FormState>();
  final _phoneForm = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _country = '+91';
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!(_emailForm.currentState?.validate() ?? false)) return;

    final ok = await ref.read(authControllerProvider.notifier).loginWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    if (ok) {
      _goAfterAuth();
    }
  }

  Future<void> _submitPhone() async {
    if (!(_phoneForm.currentState?.validate() ?? false)) return;

    final ok = await ref.read(authControllerProvider.notifier).requestOtp(
          name: 'User',
          country: _country,
          phone: _phoneCtrl.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      context.pushNamed(
        'otp',
        queryParameters: {
          if (_returnTo != null) 'returnTo': _returnTo!,
        },
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final ok =
        await ref.read(authControllerProvider.notifier).loginWithGoogle();

    if (!mounted) return;

    if (ok) {
      _goAfterAuth();
    }
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
    // rather than the StreamProvider which may not have emitted yet.
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'Welcome back',
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in to pick up where you left off.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadii.rLg,
                ),
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: palette.surface,
                    borderRadius: AppRadii.rMd,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  labelColor: palette.textPrimary,
                  unselectedLabelColor: palette.textSecondary,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: theme.textTheme.labelLarge,
                  tabs: const [
                    Tab(text: 'Email'),
                    Tab(text: 'Phone'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 500,
                child: TabBarView(
                  controller: _tab,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _emailPane(form),
                    _phonePane(form),
                  ],
                ),
              ),
              if (form.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ErrorBanner(message: form.errorMessage!),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: palette.border),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  GhostButton(
                    label: 'Create one',
                    onPressed: () {
                      final returnTo = _returnTo;
                      context.pushReplacement(
                        returnTo == null || returnTo.isEmpty
                            ? AppRoutes.signup
                            : '${AppRoutes.signup}?returnTo=${Uri.encodeComponent(returnTo)}',
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

  Widget _emailPane(AuthFormState form) {
    return Form(
      key: _emailForm,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Email',
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
              label: 'Password',
              controller: _passwordCtrl,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submitEmail(),
              validator: Validators.password,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscure = !_obscure);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => context.push('/auth/forgot-email'),
                    child: const Text(
                      'Forgot email?',
                      style: TextStyle(
                        color: AppColors.tealStrong,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Text('|', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () => context.push('/auth/forgot-password'),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: AppColors.tealStrong,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Sign in',
              size: AppButtonSize.lg,
              loading: form.isSubmitting,
              onPressed: form.isSubmitting ? null : _submitEmail,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .extension<AppPalette>()!
                              .surfaces
                              .textMuted,
                        ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: form.isSubmitting ? null : _signInWithGoogle,
                icon: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
                label: Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phonePane(AuthFormState form) {
    return Form(
      key: _phoneForm,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 110,
                  child: _CountryDropdown(
                    value: _country,
                    onChanged: (v) {
                      setState(() => _country = v);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    label: 'Mobile number',
                    controller: _phoneCtrl,
                    hintText: '98xxxxxxxx',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [
                      AutofillHints.telephoneNumberNational,
                    ],
                    onSubmitted: (_) => _submitPhone(),
                    validator: Validators.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "We'll send a one-time code to confirm it's you.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .extension<AppPalette>()!
                        .surfaces
                        .textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Send verification code',
              size: AppButtonSize.lg,
              loading: form.isSubmitting,
              onPressed: form.isSubmitting ? null : _submitPhone,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryDropdown extends StatelessWidget {
  const _CountryDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _countries = [
    ('+91', '🇮🇳 IN'),
    ('+1', '🇺🇸 US'),
    ('+44', '🇬🇧 UK'),
    ('+971', '🇦🇪 AE'),
    ('+65', '🇸🇬 SG'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country',
          style: theme.textTheme.labelLarge?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadii.rMd,
            border: Border.all(color: palette.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                AppIcons.chevronDown,
                size: 18,
              ),
              items: _countries
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.$1,
                      child: Text('${c.$2} ${c.$1}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  onChanged(v);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: AppRadii.rMd,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
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
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
