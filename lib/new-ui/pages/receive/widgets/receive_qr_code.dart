import "dart:math";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/receive/widgets/qr_image.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class ReceiveQrCode extends StatelessWidget {
  const ReceiveQrCode({
    required this.qrData,
    required this.embeddedIconAsset,
    required this.hasPayjoin,
    required this.largeQrMode,
    required this.isLightMode,
    required this.onTap,
    this.isFetching = false,
    super.key,
  });

  final String qrData;
  final String embeddedIconAsset;
  final bool hasPayjoin;
  final bool largeQrMode;
  final bool isLightMode;
  final VoidCallback onTap;
  final bool isFetching;

  static const double largeQrModeBottomPadding = 140;
  static const Duration animDuration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final targetY = largeQrMode ? largeQrModeBottomPadding + 50.0 : 0.0;
    final resolvedSize =
        min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height) * 0.5;
    final resolvedScale = largeQrMode ? 1.7 : 1.0;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AnimatedSlide(
          curve: Curves.easeOutCubic,
          duration: animDuration,
          offset: largeQrMode ? const Offset(0, -1) : Offset.zero,
          child: AnimatedOpacity(
            duration: animDuration,
            opacity: largeQrMode ? 1 : 0,
            child: CakeImageWidget(
              imageUrl: isLightMode
                  ? "assets/new-ui/cakewallet-wordmark-light.svg"
                  : "assets/new-ui/cakewallet-wordmark.svg",
              height: 45,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: targetY),
            duration: animDuration,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, value),
              child: child,
            ),
            child: Column(
              children: [
                AnimatedScale(
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  scale: resolvedScale,
                  duration: animDuration,
                  child: AnimatedContainer(
                    duration: animDuration,
                    curve: Curves.easeOutCubic,
                    width: resolvedSize,
                    height: resolvedSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        color: hasPayjoin && !largeQrMode
                            ? Theme.of(context).colorScheme.surfaceContainer
                            : Colors.transparent,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedOpacity(
                              duration: animDuration,
                              opacity: isFetching ? 0.35 : 1,
                              child: QrImage(
                                data: qrData,
                                size: resolvedSize,
                                embeddedImagePath: embeddedIconAsset,
                              ),
                            ),
                            if (isFetching) const CupertinoActivityIndicator(radius: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasPayjoin)
                  Opacity(
                    opacity: largeQrMode ? 0 : 1,
                    child: Container(
                      width: resolvedSize,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 4,
                          children: [
                            const CakeImageWidget(imageUrl: "assets/new-ui/payjoin.svg"),
                            Text(S.of(context).payjoin_enabled),
                          ],
                        ),
                      ),
                    ),
                  ),
                AnimatedSize(
                  duration: animDuration,
                  curve: Curves.easeOutCubic,
                  child: SizedBox(height: largeQrMode ? largeQrModeBottomPadding + 40 : 0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
