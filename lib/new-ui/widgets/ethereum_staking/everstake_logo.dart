import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class EverstakeLogo extends StatelessWidget {
  const EverstakeLogo({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: const CakeImageWidget(
          imageUrl: "assets/images/everstake.png",
          width: 24,
          height: 24,
        ),
      );
}
