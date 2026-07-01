import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:flutter/material.dart';

class TooltipSheet extends BaseBottomSheet {
  final String tooltip;

  const TooltipSheet({
    required super.titleText,
    super.titleIconPath,
    required this.tooltip,
    required super.footerType,
    super.maxHeight = 900,
    super.singleActionButtonText,
    super.onSingleActionButtonPressed,
    super.singleActionButtonKey,
    super.doubleActionLeftButtonText,
    super.doubleActionRightButtonText,
    super.onLeftActionButtonPressed,
    super.onRightActionButtonPressed,
    super.leftActionButtonKey,
    super.rightActionButtonKey,
  });

  @override
  Widget contentWidget(BuildContext context) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.surfaceContainer),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        child: AutoSizeText(
          tooltip,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                decoration: TextDecoration.none,
              ),
        ),
      );

  Widget footerWidget(BuildContext context) => SizedBox.shrink();
}
