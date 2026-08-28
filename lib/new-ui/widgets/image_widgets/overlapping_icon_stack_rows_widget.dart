import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class OverlappingIconStackRows extends StatelessWidget {
  const OverlappingIconStackRows({
    required this.iconPaths,
    this.itemsPerRow = 9,
    this.iconSize = 30,
    this.overlapOffset = 22,
  });

  final List<String> iconPaths;
  final int itemsPerRow;
  final double iconSize;
  final double overlapOffset;

  @override
  Widget build(BuildContext context) {
    if (iconPaths.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <List<String>>[];
    for (var i = 0; i < iconPaths.length; i += itemsPerRow) {
      rows.add(iconPaths.sublist(
        i,
        (i + itemsPerRow).clamp(0, iconPaths.length),
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map(_buildRow).toList(),
    );
  }

  Widget _buildRow(List<String> rowIconPaths) => Builder(
        builder: (context) => Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999999),
            color: Theme.of(context).colorScheme.surfaceContainerHigh.withAlpha(120),
          ),
          child: SizedBox(
            width: _rowWidth(rowIconPaths.length),
            height: iconSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ...rowIconPaths.asMap().entries.map(
                      (entry) => Positioned(
                        left: entry.key * overlapOffset,
                        child: _IconCircle(iconPath: entry.value, size: iconSize),
                      ),
                    ),
              ],
            ),
          ),
        ),
      );

  double _rowWidth(int count) {
    if (count <= 0) {
      return 0;
    }
    return iconSize + ((count - 1) * overlapOffset);
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.iconPath, required this.size});

  final String iconPath;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: CakeImageWidget(
            imageUrl: iconPath,
            width: size,
            height: size,
          ),
        ),
      );
}
