import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.teal.withValues(alpha: 0.1),
                  AppColors.tealStrong.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadii.rLg,
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: AppRadii.rMd,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.tealStrong,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How can we help?',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse FAQs or contact support',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // FAQ Section
          Text(
            'Frequently asked questions',
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _FaqItem(
            question: 'How do I book a ticket?',
            answer:
                'Search for your route, select a bus, enter passenger details, and complete the payment. Your QR ticket will be generated instantly.',
          ),
          _FaqItem(
            question: 'How do I cancel a ticket?',
            answer:
                'Go to My Tickets, tap on the ticket you want to cancel, and press the Cancel button. Refund is processed based on the cancellation policy.',
          ),
          _FaqItem(
            question: 'How does the wallet work?',
            answer:
                'Add money to your wallet via UPI, cards, or net banking. Use your wallet balance for quick ticket purchases without entering payment details each time.',
          ),
          _FaqItem(
            question: 'What is a QR ticket?',
            answer:
                'After booking, you receive a QR code ticket. Show this to the bus conductor who will scan it to validate your ride.',
          ),
          _FaqItem(
            question: 'How do I reset my password?',
            answer:
                'Tap "Forgot Password" on the login screen, enter your registered email, and follow the instructions in the reset email.',
          ),
          _FaqItem(
            question: 'Is my payment secure?',
            answer:
                'Yes. All payments are processed through secure, PCI-compliant payment gateways. We never store your card or UPI details.',
          ),

          const SizedBox(height: AppSpacing.xl),

          // Contact Section
          Text(
            'Still need help?',
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadii.rMd,
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                _ContactRow(
                  icon: Icons.email_outlined,
                  label: 'support@busconductor.com',
                ),
                const SizedBox(height: AppSpacing.md),
                _ContactRow(
                  icon: Icons.phone_outlined,
                  label: '1800-123-4567 (Toll-free)',
                ),
                const SizedBox(height: AppSpacing.md),
                _ContactRow(
                  icon: Icons.access_time_rounded,
                  label: '9 AM – 9 PM IST, Mon – Sat',
                ),
              ],
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadii.rMd,
          border: Border.all(color: palette.border),
        ),
        child: InkWell(
          borderRadius: AppRadii.rMd,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: palette.textMuted,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.answer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.tealSoft,
            borderRadius: AppRadii.rSm,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.tealStrong),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
