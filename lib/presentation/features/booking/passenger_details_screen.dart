import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../auth/auth_controller.dart';
import 'booking_controller.dart';
import 'widgets/booking_stepper.dart';

/// Step 2 of the booking flow — the primary passenger's name, phone and
/// optional email. Prefilled from the active auth session when available.
class PassengerDetailsScreen extends ConsumerStatefulWidget {
  const PassengerDetailsScreen({super.key});

  @override
  ConsumerState<PassengerDetailsScreen> createState() =>
      _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState
    extends ConsumerState<PassengerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  int _passengerCount = 1;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(bookingControllerProvider);
    final session = ref.read(authSessionProvider).valueOrNull;
    _name = TextEditingController(
      text: draft?.passengerName ?? session?.user.displayName ?? '',
    );
    _phone = TextEditingController(
      text: draft?.passengerPhone ?? session?.user.phone ?? '',
    );
    _email = TextEditingController(
      text: draft?.passengerEmail ?? session?.user.email ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(bookingControllerProvider.notifier)
      ..setPassenger(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        passengerCount: _passengerCount,
      )
      ..setStage(BookingStage.payment);
    context.push('/booking/payment');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final draft = ref.watch(bookingControllerProvider);

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: ErrorStateView(
            title: 'No active booking',
            message: 'Please start a booking from a route.',
            onRetry: () => context.pop(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Passenger details'),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const BookingStepper(current: BookingStage.passenger),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SeatSummary(passengerCount: _passengerCount),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Number of passengers',
                          style: theme.textTheme.titleMedium,),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Select how many tickets you need. Details below are for the lead passenger only.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: AppRadii.rMd,
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              color: palette.textMuted,
                              onPressed: _passengerCount > 1
                                  ? () => setState(() => _passengerCount--)
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              '$_passengerCount ${_passengerCount == 1 ? 'passenger' : 'passengers'}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              Money.format(_passengerCount * (draft?.total ?? 0)),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.tealStrong,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              color: AppColors.tealStrong,
                              onPressed: _passengerCount < 10
                                  ? () => setState(() => _passengerCount++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Lead passenger details',
                          style: theme.textTheme.titleMedium,),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Only the lead passenger needs to provide details. '
                        'Other passengers travel under this booking reference.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Full name',
                        controller: _name,
                        hintText: 'As on your ID',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) =>
                            (v ?? '').trim().length < 2 ? 'Enter a valid name' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Phone number',
                        controller: _phone,
                        hintText: '10-digit mobile',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        autofillHints: const [
                          AutofillHints.telephoneNumberNational,
                        ],
                        validator: (v) =>
                            (v ?? '').trim().length < 7 ? 'Enter a valid phone' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Email (optional)',
                        controller: _email,
                        hintText: 'you@example.com',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return null;
                          return t.contains('@') && t.contains('.')
                              ? null
                              : 'Enter a valid email';
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _ContactConsent(),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: PrimaryButton(
                label: 'Continue to payment',
                icon: AppIcons.chevronRight,
                size: AppButtonSize.lg,
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatSummary extends ConsumerWidget {
  const _SeatSummary({required this.passengerCount});
  final int passengerCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    final draft = ref.watch(bookingControllerProvider)!;
    final totalPrice = passengerCount * draft.totalPerTicket;
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
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: AppRadii.rSm,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.route_rounded,
                color: AppColors.tealStrong, size: 20,),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${draft.from.name} → ${draft.to.name}',
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${draft.totalPerTicket} × $passengerCount ${passengerCount == 1 ? 'ticket' : 'tickets'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Money.format(totalPrice),
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.tealStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactConsent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: palette.textMuted, size: 18,),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Your details are used only for this booking and trip updates. '
              'They are never shared with third parties.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
