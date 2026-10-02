import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';

class StandardSwitch extends StatefulWidget {
  const StandardSwitch({
    required this.value,
    required this.onTapped,
    this.backgroundColor,
    this.isCompact = false,
  });

  final bool value;
  final Color? backgroundColor;
  final VoidCallback onTapped;
  final bool isCompact;
  @override
  StandardSwitchState createState() => StandardSwitchState();
}

class StandardSwitchState extends State<StandardSwitch> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final knobSize = widget.isCompact ? 20.0 : 24.0;
    final offColor = widget.isCompact
        ? widget.backgroundColor ?? colors.surfaceContainerHighest
        : widget.backgroundColor ?? context.currentTheme.customColors.toggleColorOffState;
    final knobColor = widget.isCompact
        ? colors.onPrimary
        : context.currentTheme.isDark
            ? colors.surface
            : context.currentTheme.customColors.toggleKnobStateColor;

    return Semantics(
      toggled: widget.value,
      child: GestureDetector(
        onTap: widget.onTapped,
        child: AnimatedContainer(
          padding: EdgeInsets.only(left: 2.0, right: 2.0),
          alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
          duration: Duration(milliseconds: 250),
          width: widget.isCompact ? 40 : 50,
          height: widget.isCompact ? 24 : 28,
          decoration: BoxDecoration(
            color: widget.value ? colors.primary : offColor,
            borderRadius: BorderRadius.all(Radius.circular(widget.isCompact ? 12 : 14)),
          ),
          child: Container(
            width: knobSize,
            height: knobSize,
            decoration: BoxDecoration(color: knobColor, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
