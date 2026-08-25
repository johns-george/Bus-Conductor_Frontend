import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/user.dart';
import '../../providers/repository_providers.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../auth/auth_controller.dart';

/// Profile tab — user card, preferences (including theme), and account
/// actions. Theme toggle is fully functional.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final session = ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => context.push(AppRoutes.help),
            tooltip: 'Help',
          ),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          120,
        ),
        children: [
          if (session == null)
            _GuestCard(onLogin: () => context.go(AppRoutes.authWelcome))
          else
            _UserCard(
              name: session.user.displayName,
              email: session.user.email,
              phone: session.user.phone,
              onEdit: () => _showEditProfile(context, ref, session.user),
            ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Preferences'),
          const _ThemePicker(),
          const SizedBox(height: AppSpacing.sm),
          const _NotificationToggle(),
          const SizedBox(height: AppSpacing.sm),
          _SettingsCard(
            items: [
              _SettingsItem(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English (India)',
                trailing: const Icon(AppIcons.chevronRight, size: 18),
                onTap: () => _showLanguagePicker(context),
              ),
              _SettingsItem(
                icon: Icons.travel_explore_rounded,
                title: 'Home city',
                subtitle: 'Set your default departure city',
                trailing: const Icon(AppIcons.chevronRight, size: 18),
                onTap: () => _showHomeCityPicker(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Account'),
          _SettingsCard(
            items: [
              _SettingsItem(
                icon: Icons.credit_card_rounded,
                title: 'Payment methods',
                subtitle: 'UPI, cards, net banking',
                trailing: const Icon(AppIcons.chevronRight, size: 18),
                onTap: () => context.push(AppRoutes.paymentMethods),
              ),
              _SettingsItem(
                icon: Icons.shield_outlined,
                title: 'Privacy & data',
                trailing: const Icon(AppIcons.chevronRight, size: 18),
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Privacy & Data',
                  icon: Icons.shield_outlined,
                  body: 'Your data is encrypted and never shared with third parties. We only store what is necessary to operate the service. You can request full data deletion from the help center.',
                ),
              ),
              _SettingsItem(
                icon: Icons.history_rounded,
                title: 'Trip history',
                trailing: const Icon(AppIcons.chevronRight, size: 18),
                onTap: () => context.go(AppRoutes.tickets),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Support'),
          _SettingsCard(
            items: [
              _SettingsItem(
                icon: Icons.help_center_outlined,
                title: 'Help center',
                trailing: const Icon(AppIcons.chevronRight, size: 18),
                onTap: () => context.push(AppRoutes.help),
              ),
              _SettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'About Bus Conductor',
                subtitle: 'Version 0.1.0 (demo build)',
                trailing: const Icon(AppIcons.chevronRight, size: 18),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (session != null)
            SecondaryButton(
              label: 'Log out',
              icon: Icons.logout_rounded,
              size: AppButtonSize.lg,
              onPressed: () => _confirmLogout(context, ref),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _showEditProfile(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final nameController = TextEditingController(text: user.displayName);
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');
    final messenger = ScaffoldMessenger.of(context);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(sheetCtx).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit profile',
                  style: Theme.of(sheetCtx).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Save changes',
                icon: Icons.check_rounded,
                size: AppButtonSize.lg,
                onPressed: () => Navigator.of(sheetCtx).pop(true),
              ),
            ],
          ),
        );
      },
    );

    if (result != true || !context.mounted) return;

    final updated = user.copyWith(
      displayName: nameController.text.trim().isNotEmpty
          ? nameController.text.trim()
          : user.displayName,
      email: emailController.text.trim().isNotEmpty
          ? emailController.text.trim()
          : user.email,
      phone: phoneController.text.trim().isNotEmpty
          ? phoneController.text.trim()
          : user.phone,
    );

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final savedUser = await userRepo.updateProfile(updated);
      // Update the auth session in-memory so the UI refreshes
      await ref.read(authRepositoryProvider).updateUser(savedUser);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showLanguagePicker(BuildContext context) {
    const languages = [
      ('English', 'en', Icons.language),
      ('Hindi', 'hi', Icons.translate),
      ('Kannada', 'kn', Icons.translate),
      ('Tamil', 'ta', Icons.translate),
      ('Telugu', 'te', Icons.translate),
      ('Malayalam', 'ml', Icons.translate),
      ('Marathi', 'mr', Icons.translate),
      ('Bengali', 'bn', Icons.translate),
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: languages.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final (name, code, icon) = languages[i];
                return ListTile(
                  leading: Icon(icon, color: AppColors.tealStrong),
                  title: Text(name),
                  trailing: code == 'en'
                      ? const Icon(Icons.check_circle, color: AppColors.tealStrong)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(code == 'en'
                            ? 'Already using English'
                            : '$name will be available in the next update'),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showHomeCityPicker(BuildContext context) {
    const cities = [
      'Bangalore', 'Mumbai', 'Delhi', 'Chennai', 'Hyderabad',
      'Pune', 'Kolkata', 'Kochi', 'Mysore', 'Goa',
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final palette = theme.extension<AppPalette>()!.surfaces;
        return AlertDialog(
          title: const Text('Set Home City'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose your default departure city for faster booking.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    return ListTile(
                      leading: const Icon(
                        Icons.location_city_rounded,
                        color: AppColors.tealStrong,
                      ),
                      title: Text(cities[i]),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Home city set to ${cities[i]}'),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, {
    required String title,
    required IconData icon,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, size: 36, color: AppColors.tealStrong),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Bus Conductor',
      applicationVersion: '0.1.0',
      applicationIcon: const Icon(Icons.directions_bus_rounded, color: AppColors.tealStrong, size: 40),
      children: const [
        Text('An intelligent bus ticketing platform with real-time route search, QR-based tickets, wallet payments, and conductor validation.'),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You can sign back in anytime. Saved routes stay linked to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    context.go(AppRoutes.authWelcome);
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.onEdit,
  });

  final String name;
  final String? email;
  final String? phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initialsOf(name);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: AppRadii.rLg,
        gradient: LinearGradient(
          colors: [AppColors.midnight, AppColors.midnightSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.teal, AppColors.tealStrong],
              ),
              borderRadius: AppRadii.rMd,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email ?? phone ?? 'Bus Conductor member',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                GhostButton(
                  label: 'Edit profile',
                  onPressed: onEdit,
                  icon: Icons.edit_outlined,
                  tone: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsOf(String n) {
    final parts = n.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: AppRadii.rLg,
        color: AppColors.tealSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.rMd,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person_outline_rounded,
                color: AppColors.tealStrong, size: 28,),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Browsing as guest',
                    style: theme.textTheme.titleMedium,),
                const SizedBox(height: 2),
                Text(
                  'Log in to save routes, view tickets, and manage payments.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(onPressed: onLogin, child: const Text('Log in')),
        ],
      ),
    );
  }
}

class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final modeAsync = ref.watch(themeModeProvider);
    final current = modeAsync.valueOrNull ?? ThemeMode.system;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: AppRadii.rSm,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.palette_outlined,
                    color: AppColors.tealStrong, size: 20,),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      _subtitleFor(current),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ThemeSegmented(current: current),
        ],
      ),
    );
  }

  String _subtitleFor(ThemeMode m) => switch (m) {
        ThemeMode.system => 'Matches your device',
        ThemeMode.light => 'Always bright',
        ThemeMode.dark => 'Always dark',
      };
}

class _ThemeSegmented extends ConsumerWidget {
  const _ThemeSegmented({required this.current});
  final ThemeMode current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadii.rSm,
      ),
      child: Row(
        children: [
          _segment(
            context,
            ref,
            label: 'System',
            icon: Icons.phone_iphone_rounded,
            mode: ThemeMode.system,
          ),
          _segment(
            context,
            ref,
            label: 'Light',
            icon: Icons.light_mode_rounded,
            mode: ThemeMode.light,
          ),
          _segment(
            context,
            ref,
            label: 'Dark',
            icon: Icons.dark_mode_rounded,
            mode: ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required ThemeMode mode,
  }) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final selected = current == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeModeProvider.notifier).setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? palette.surface : Colors.transparent,
            borderRadius: AppRadii.rSm,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.tealStrong : palette.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color:
                      selected ? AppColors.tealStrong : palette.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatefulWidget {
  const _NotificationToggle();

  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadii.rSm,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.notifications_none_rounded,
                size: 18, color: palette.textSecondary,),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Trip reminders, offers, updates',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.items});
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: items[i].onTap,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.md),)
                  : i == items.length - 1
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(AppRadii.md),)
                      : BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadii.rSm,
                      ),
                      alignment: Alignment.center,
                      child: Icon(items[i].icon,
                          size: 18, color: palette.textSecondary,),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].title,
                              style: theme.textTheme.titleSmall,),
                          if (items[i].subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              items[i].subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (items[i].trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      items[i].trailing!,
                    ],
                  ],
                ),
              ),
            ),
            if (i < items.length - 1) Divider(color: palette.border, height: 1),
          ],
        ],
      ),
    );
  }
}
