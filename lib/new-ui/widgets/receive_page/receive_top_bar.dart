import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:flutter/material.dart';

void nothing(){}

class ModalTopBar extends StatelessWidget {
  ModalTopBar(
      {super.key,
      required this.title,
      this.onLeadingPressed=nothing,
      this.onTrailingPressed=nothing,
      this.leadingIcon,
      this.trailingIcon,
      this.leadingWidget,
      this.trailingWidget}) {
    if(leadingIcon != null && leadingWidget != null) {
      throw Exception("Cannot have both leadingIcon and leadingWidget");
    }
    if(trailingIcon != null && trailingWidget != null) {
      throw Exception("Cannot have both trailingIcon and trailingWidget");
    }
  }

  final String title;
  final VoidCallback onLeadingPressed;
  final VoidCallback onTrailingPressed;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final Widget? leadingWidget;
  final Widget? trailingWidget;

  static const buttonSize = 36.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leadingIcon != null)
                ModernButton(size: buttonSize, onPressed: onLeadingPressed, icon: leadingIcon!)
              else if (leadingWidget != null) leadingWidget!
              else
                Container(width: buttonSize),

              if (trailingIcon != null)
                ModernButton(size: buttonSize, onPressed: onTrailingPressed, icon: trailingIcon!)
              else if (trailingWidget != null) trailingWidget!
              else
                Container(width: buttonSize),
            ],
          ),
        ],
      ),
    );
  }
}