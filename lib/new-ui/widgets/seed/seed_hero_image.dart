import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class SeedHeroImage extends StatelessWidget {
  const SeedHeroImage({this.showWarningBadge = false, super.key});

  final bool showWarningBadge;

  @override
  Widget build(BuildContext context) {
    final name = showWarningBadge ? "seed_warning" : "seed_shield";
    final variant = Theme.of(context).brightness == Brightness.dark ? "dark" : "light";

    return CakeImageWidget(
      imageUrl: "assets/new-ui/hero/${name}_$variant.svg",
      width: 200,
      height: 228.57,
    );
  }
}
