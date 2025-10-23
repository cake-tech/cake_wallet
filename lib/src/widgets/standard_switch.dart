import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';

class StandardSwitch extends StatefulWidget {
  const StandardSwitch({
    required this.value,
    required this.onTapped,
    this.backgroundColor,
  });

  final bool value;
  final Color? backgroundColor;
  final VoidCallback onTapped;
  @override
  StandardSwitchState createState() => StandardSwitchState();
}

class StandardSwitchState extends State<StandardSwitch> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: widget.value,
      child: GestureDetector(
        onTap: widget.onTapped,
        child: AnimatedContainer(
          padding: EdgeInsets.only(left: 2.0, right: 2.0),
          alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
          duration: Duration(milliseconds: 250),
          width: 50,
          height: 28,
          decoration: BoxDecoration(
            color: widget.value
                ? Theme.of(context).colorScheme.primary
                : widget.backgroundColor ?? context.currentTheme.customColors.toggleColorOffState,
            borderRadius: BorderRadius.all(Radius.circular(14.0)),
          ),
          child: Container(
            width: 24.0,
            height: 24.0,
            decoration: BoxDecoration(
              color: context.currentTheme.isDark
                  ? Theme.of(context).colorScheme.surface
                  : context.currentTheme.customColors.toggleKnobStateColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
