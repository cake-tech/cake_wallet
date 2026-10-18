import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class BorderedSvgIcon extends StatelessWidget {
  const BorderedSvgIcon({
    required this.iconPath,
    required this.iconSize,
    Color? iconColor,
    Color? borderColor,
    this.borderSize = 6,
    super.key,
  })  : _iconColor = iconColor,
        _borderColor = borderColor;

  final String iconPath;
  final Color? _iconColor;
  final double iconSize;
  final Color? _borderColor;
  final double borderSize;

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor ?? Theme.of(context).colorScheme.onSurface;
    final borderColor = _borderColor ?? Theme.of(context).colorScheme.surface;

    return SizedBox(
      width: iconSize + borderSize * 2,
      height: iconSize + borderSize * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CakeImageWidget(
            imageUrl: iconPath,
            width: iconSize + borderSize * 2,
            height: iconSize + borderSize * 2,
            colorFilter: ColorFilter.mode(
              borderColor,
              BlendMode.srcIn,
            ),
          ),
          CakeImageWidget(
            imageUrl: iconPath,
            width: iconSize,
            height: iconSize,
            colorFilter: ColorFilter.mode(
              iconColor,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
