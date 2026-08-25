import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/app_bootstrap_provider.dart';
import '../../widgets/buttons/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: AppIcons.route,
      eyebrow: 'Plan',
      title: 'Find the right bus, instantly.',
      body:
          'Smart stop search, clear fares, and the next bus time for every route — all in one screen.',
      accent: AppColors.teal,
    ),
    _OnboardingSlide(
      icon: AppIcons.ticket,
      eyebrow: 'Book',
      title: 'A ticket, three taps away.',
      body:
          'Skip the queue. Book a seat in seconds and carry a QR pass straight on your phone.',
      accent: AppColors.amber,
    ),
    _OnboardingSlide(
      icon: AppIcons.qr,
      eyebrow: 'Board',
      title: 'Scan, ride, done.',
      body:
          'Show your QR to the conductor and your ticket activates the moment you step in.',
      accent: AppColors.coral,
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await ref.read(appBootstrapProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.authWelcome);
  }

  void _next() {
    if (_isLast) {
      _complete();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                    right: AppSpacing.sm, top: AppSpacing.sm,),
                child: TextButton(
                  onPressed: _complete,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl2,
                AppSpacing.lg,
                AppSpacing.xl2,
                AppSpacing.xl2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          width: i == _page ? 22 : 8,
                          height: 8,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: i == _page
                                ? Theme.of(context).colorScheme.primary
                                : palette.border,
                            borderRadius: AppRadii.rPill,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: _isLast ? 'Start exploring' : 'Next',
                    onPressed: _next,
                    size: AppButtonSize.lg,
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

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IllustrationBlock(slide: slide),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                slide.eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: slide.accent,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                slide.title,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                slide.body,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: palette.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IllustrationBlock extends StatelessWidget {
  const _IllustrationBlock({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return AspectRatio(
      aspectRatio: 1.15,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadii.rXl,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    slide.accent.withValues(alpha: 0.22),
                    slide.accent.withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.xl2,
            top: AppSpacing.xl2,
            child: _Chip(label: 'Live', tone: slide.accent),
          ),
          Positioned(
            right: AppSpacing.xl2,
            top: AppSpacing.xl2 + 40,
            child: _Chip(
              label: '501',
              tone: slide.accent,
              filled: true,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadii.rXl,
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: slide.accent.withValues(alpha: 0.18),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Icon(slide.icon, size: 64, color: slide.accent),
            ),
          ),
          Positioned(
            left: AppSpacing.xl2,
            bottom: AppSpacing.xl2,
            right: AppSpacing.xl2,
            child: _MiniInfoRow(tone: slide.accent),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({required this.tone});
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md,),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: AppRadii.rSm,
            ),
            child: Icon(AppIcons.clock, size: 14, color: tone),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next bus',
                    style: Theme.of(context).textTheme.labelSmall,),
                Text(
                  'In 6 min',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          Text(
            '\u20B955',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tone, this.filled = false});
  final String label;
  final Color tone;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? tone : tone.withValues(alpha: 0.14),
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: filled ? Colors.white : tone,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.accent,
  });
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final Color accent;
}
