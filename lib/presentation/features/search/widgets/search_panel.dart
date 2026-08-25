import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/stop.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/inputs/stop_field.dart';
import '../search_controller.dart';
import 'stop_picker_sheet.dart';

/// The core search card. Stops, swap, dates, validate & submit.
class SearchPanel extends ConsumerWidget {
  const SearchPanel({super.key, required this.onSubmit});

  final void Function(Stop from, Stop to, DateTime? date) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final state = ref.watch(searchFormProvider);
    final controller = ref.read(searchFormProvider.notifier);

    Future<void> pickFrom() async {
      final stop = await StopPickerSheet.show(
        context,
        title: 'Choose starting stop',
        hint: 'Search by stop, area, or city',
        excludeStopId: state.to?.id,
      );
      if (stop != null) controller.setFrom(stop);
    }

    Future<void> pickTo() async {
      final stop = await StopPickerSheet.show(
        context,
        title: 'Choose destination',
        hint: 'Search by stop, area, or city',
        excludeStopId: state.from?.id,
      );
      if (stop != null) controller.setTo(stop);
    }

    void submit() {
      final error = controller.validate();
      if (error != null) {
        controller.setError(error);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      onSubmit(state.from!, state.to!, state.date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Column(
                children: [
                  StopPickerField(
                    kind: StopFieldKind.from,
                    value: state.from,
                    onTap: pickFrom,
                    onClear: controller.clearFrom,
                  ),
                  Divider(height: 1, color: palette.border),
                  StopPickerField(
                    kind: StopFieldKind.to,
                    value: state.to,
                    onTap: pickTo,
                    onClear: controller.clearTo,
                  ),
                ],
              ),
              Positioned(
                right: AppSpacing.md,
                child: _SwapButton(onPressed: controller.swap),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: PrimaryButton(
              label: 'Search buses',
              onPressed: submit,
              icon: AppIcons.search,
              size: AppButtonSize.lg,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _SwapButton extends StatefulWidget {
  const _SwapButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<_SwapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handle() {
    _controller.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: palette.surface,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _handle,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.borderStrong),
            color: palette.surface,
          ),
          child: RotationTransition(
            turns: Tween<double>(begin: 0, end: 0.5).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
            child: Icon(AppIcons.swap, color: scheme.primary, size: 20),
          ),
        ),
      ),
    );
  }
}
