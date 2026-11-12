import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class DefiProviderLogo extends StatelessWidget {
  const DefiProviderLogo(this.imageUrl, {super.key});

  final String imageUrl;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CakeImageWidget(imageUrl: imageUrl, width: 24, height: 24),
      );
}
