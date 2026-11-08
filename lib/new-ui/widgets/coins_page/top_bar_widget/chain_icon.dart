import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class ChainIcon extends StatelessWidget {
  const ChainIcon({
    required this.iconPath, required this.openChainSelection, super.key,
  });

  static const _containerRadius = 12.0;
  static const _iconRadius = 8.0;

  final String iconPath;
  final VoidCallback openChainSelection;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_containerRadius),
          onTap: () {
            HapticFeedback.mediumImpact();
            openChainSelection();
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_containerRadius),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(_iconRadius),
                  child: CakeImageWidget(
                    imageUrl: iconPath,
                    width: 28,
                    height: 28,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      );
}
