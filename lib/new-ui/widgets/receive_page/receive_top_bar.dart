import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:flutter/material.dart';

class ModalTopBar extends StatelessWidget {
  const ModalTopBar(
      {super.key,
      required this.title,
      required this.onLeadingPressed,
      required this.onTrailingPressed,
      this.leadingIcon,
      this.trailingIcon});

  final String title;
  final VoidCallback onLeadingPressed;
  final VoidCallback onTrailingPressed;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  static const buttonSize = 36.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (leadingIcon != null)
            ModernButton(size: buttonSize, onPressed: onLeadingPressed, icon: leadingIcon!)
          else
            Container(width: buttonSize),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (trailingIcon != null)
            ModernButton(size: buttonSize, onPressed: onTrailingPressed, icon: trailingIcon!)
          else
            Container(width: buttonSize),
        ],
      ),
    );
  }
}