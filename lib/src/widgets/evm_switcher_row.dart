import 'package:cake_wallet/src/widgets/evm_switcher.dart';
import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EvmSwitcherRow extends StatelessWidget {
  const EvmSwitcherRow({
    super.key,
    required this.editMode,
    required this.selected,
    required this.data,
    required this.onTap,
    required this.animDuration,
    required this.editSwitchValue,
  });

  final bool editMode;
  final bool selected;
  final EvmSwitcherDataItem data;
  final VoidCallback onTap;
  final Duration animDuration;
  final bool editSwitchValue;

  @override
  Widget build(BuildContext context) {
    final Color resolvedForegroundColor = editMode || selected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.primary;

    final Color resolvedBackgroundColor = !editMode && selected
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: animDuration,
        color: resolvedBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 8.0,
                children: [
                  SvgPicture.asset(
                    data.svgPath,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                        resolvedForegroundColor, BlendMode.srcIn),
                  ),
                  Text(data.name,
                      style: TextStyle(
                          color: resolvedForegroundColor, fontSize: 14)),
                  if (selected && !editMode)
                    SvgPicture.asset("assets/images/evm_switcher_checkmark.svg",
                        width: 18, height: 18),
                ],
              ),
              if (editMode)
                StandardSwitch(value: editSwitchValue, onTapped: onTap)
            ],
          ),
        ),
      ),
    );
  }
}
