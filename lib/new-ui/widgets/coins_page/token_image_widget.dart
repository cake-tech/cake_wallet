
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
    final needsBackdrop = !imageUrl.contains('crypto_full_icons/');

    final image = SizedBox(
      width: size,
      height: size,
      child: CakeImageWidget(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: errorWidget,
      ),
    );

    if (!needsBackdrop) {
      return ClipOval(child: image);
    }

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      child: image,
    );
  }
}
