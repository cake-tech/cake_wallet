
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class TokenImageWidget extends StatelessWidget {
  const TokenImageWidget({
    super.key,
    required this.imageUrl,
    required this.size,
    this.errorWidget,
  });

  final String imageUrl;
  final double size;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      child: Transform.scale(
        scale: 1.08,
        child: CakeImageWidget(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: errorWidget,
        ),
      ),
    );
  }
}
