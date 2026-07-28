import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class ReceiveLabelWidget extends StatelessWidget {
  const ReceiveLabelWidget({
    required this.name,
    required this.largeQrMode,
    super.key,
  });

  final String name;
  final bool largeQrMode;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: largeQrMode || name.isEmpty ? 0 : 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            spacing: 8,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRect(
                child: CakeImageWidget(
                  imageUrl: "assets/new-ui/label.svg",
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Text(
                name,
                style:
                    TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
}
