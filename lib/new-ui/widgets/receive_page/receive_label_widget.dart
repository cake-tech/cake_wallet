import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class ReceiveLabelWidget extends StatelessWidget {
  const ReceiveLabelWidget({
    required this.label,
    required this.largeQrMode,
    super.key,
  });

  final String label;
  final bool largeQrMode;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: largeQrMode || label.isEmpty ? 0 : 36,
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
              ExcludeSemantics(
                child: ClipRect(
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
              ),
              Text(
                label,
                style:
                    TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
}
