import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/cupertino.dart";

class IconCluster extends StatelessWidget {
  const IconCluster({
    required this.iconPaths,
    this.itemSize = 34,
    this.spacing = 6,
    this.crossAxisCount = 2,
    this.borderRadius = 10,
  });

  final List<String> iconPaths;
  final double itemSize;
  final double spacing;
  final int crossAxisCount;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        spacing: spacing,
        children: [
          for (var i = 0; i < iconPaths.length; i += crossAxisCount)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: spacing,
              children: iconPaths
                  .sublist(i, (i + crossAxisCount).clamp(0, iconPaths.length))
                  .map(_buildIconTile)
                  .toList(),
            ),
        ],
      );

  Widget _buildIconTile(String iconPath) => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CakeImageWidget(
          imageUrl: iconPath,
          height: itemSize,
          width: itemSize,
        ),
      );
}
