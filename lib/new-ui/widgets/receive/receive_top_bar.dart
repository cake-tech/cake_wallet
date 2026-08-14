import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:flutter/material.dart";

void nothing() {}

class ModalTopBar extends StatelessWidget {
  ModalTopBar({
    required this.title,
    super.key,
    this.subtitle,
    this.onLeadingPressed = nothing,
    this.onTrailingPressed = nothing,
    this.leadingIcon,
    this.trailingIcon,
    this.padding,
    this.leadingWidget,
    this.trailingWidget,
    this.leadingSemanticLabel,
    this.trailingSemanticLabel,
  }) {
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

  /// Accessible name for the leading chrome button. Required (non-empty)
  /// whenever a [leadingIcon] is supplied — the icon alone doesn't say
  /// whether it closes the modal or navigates back. Caller must localize.
  final String? leadingSemanticLabel;

  /// Accessible name for the trailing chrome button. Required (non-empty)
  /// whenever a [trailingIcon] is supplied. Caller must localize.
  final String? trailingSemanticLabel;

  static const buttonSize = 36.0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.all(18),
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Semantics(
                      key: ValueKey(title),
                      header: title.isNotEmpty,
                      // Android reads the heading from headingLevel since the
                      // Flutter 3.41 engine; header: alone only covers iOS.
                      headingLevel: title.isNotEmpty ? 1 : null,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
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
                          icon: leadingIcon,
                          semanticLabel: leadingSemanticLabel,
                          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
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
                            icon: trailingIcon,
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
