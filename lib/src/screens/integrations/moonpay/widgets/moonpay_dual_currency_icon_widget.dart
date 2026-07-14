import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class DualCurrencyIcon extends StatelessWidget {
  const DualCurrencyIcon({
    super.key,
    this.leftImagePath,
    this.rightImagePath,
    this.leftWidget,
    this.rightWidget,
    this.size = 90,
    this.overlap = 20,
    this.backgroundColor,
  });

  final String? leftImagePath;
  final String? rightImagePath;
  final Widget? leftWidget;
  final Widget? rightWidget;
  final double size;
  final double overlap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + (size - overlap),
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: size - overlap,
            child: _CircleWrapper(
              size: size,
              backgroundColor: backgroundColor,
              imagePath: leftImagePath,
              child: leftWidget,
            ),
          ),
          Positioned(
            left: 0,
            child: _CircleWrapper(
              size: size,
              backgroundColor: backgroundColor,
              imagePath: rightImagePath,
              child: rightWidget,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleWrapper extends StatelessWidget {
  const _CircleWrapper({
    required this.size,
    this.imagePath,
    this.child,
    this.backgroundColor,
  });

  final double size;
  final String? imagePath;
  final Widget? child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Theme.of(context).colorScheme.primary,
      ),
      alignment: Alignment.center,
      child: child ??
          (imagePath != null && imagePath!.isNotEmpty
              ? SizedBox(
                  width: size * 0.94,
                  height: size * 0.94,
                  child: CakeImageWidget(
                    imageUrl: imagePath,
                    height: size * 0.9,
                    width: size * 0.9,
                    fit: BoxFit.contain,
                  ),
                )
              : const SizedBox.shrink()),
    );
  }
}
