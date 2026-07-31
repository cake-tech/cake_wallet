import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:flutter/material.dart';

void nothing() {}

class ModalTopBar extends StatelessWidget {
  ModalTopBar(
      {super.key,
      required this.title,
      this.subtitle,
      this.onLeadingPressed = nothing,
      this.onTrailingPressed = nothing,
      this.leadingIcon,
      this.trailingIcon,
      this.padding,
      this.leadingWidget,
      this.trailingWidget,
      this.leadingSemanticLabel,
      this.trailingSemanticLabel}) {
    if (leadingIcon != null && leadingWidget != null) {
      throw Exception("Cannot have both leadingIcon and leadingWidget");
    }
    if (trailingIcon != null && trailingWidget != null) {
      throw Exception("Cannot have both trailingIcon and trailingWidget");
    }
  }

  final String title;
  final String? subtitle;
  final VoidCallback onLeadingPressed;
  final VoidCallback onTrailingPressed;
  final Widget? leadingIcon;
  final EdgeInsets? padding;
  final Widget? trailingIcon;
  final Widget? leadingWidget;
  final Widget? trailingWidget;

  /// Accessible name for the leading chrome button. Defaults to "Close" because
  /// the leading icon is a close/back affordance in nearly every modal.
  final String? leadingSemanticLabel;

  /// Accessible name for the trailing chrome button. Callers should supply one
  /// whenever they supply a [trailingIcon].
  final String? trailingSemanticLabel;

  static const buttonSize = 36.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.all(18),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 6,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                Semantics(
                  header: title.isNotEmpty,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      title,
                      key: ValueKey(title),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leadingIcon != null || leadingWidget != null)
                leadingIcon != null
                    ? ModernButton(
                        key: ValueKey(leadingIcon.hashCode),
                        size: buttonSize,
                        onPressed: onLeadingPressed,
                        icon: leadingIcon!,
                        semanticLabel: leadingSemanticLabel ?? S.of(context).close,
                        iconColor: Theme.of(context).colorScheme.onSurfaceVariant)
                    : leadingWidget!
              else
                Container(width: buttonSize),
              if (trailingIcon != null || trailingWidget != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: trailingIcon != null
                      ? ModernButton(
                          key: ValueKey(trailingIcon.hashCode),
                          size: buttonSize,
                          onPressed: onTrailingPressed,
                          icon: trailingIcon!,
                          semanticLabel: trailingSemanticLabel,
                        )
                      : trailingWidget!,
                )
              else
                Container(width: buttonSize),
            ],
          ),
        ],
      ),
    );
  }
}
