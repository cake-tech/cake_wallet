import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FloatingIconButton extends StatelessWidget {
  const FloatingIconButton({
    super.key,
    required this.iconPath,
    required this.onPressed,
    required this.semanticLabel,
  });

  final String iconPath;
  final VoidCallback onPressed;

  /// Localized accessible name for this icon-only button. The icon itself stays
  /// decorative, so this is the only name a screen reader can announce.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: CakeImageWidget(
                  imageUrl: iconPath,
                  width: 22,
                  height: 22,
                  colorFilter:
                      ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                ),
              )),
        ),
      ),
    );
  }
}
