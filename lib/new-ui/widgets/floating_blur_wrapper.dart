import 'dart:ui';

import 'package:flutter/cupertino.dart';

class FloatingBlurWrapper extends StatelessWidget {
  const FloatingBlurWrapper({
    super.key,
    required this.child,
    this.horizontalPadding = 20.0,
    this.verticalPadding = 8.0,
    this.blurSigma = 1.0,
    this.borderRadius = 999999,
  });

  final Widget child;
  final double horizontalPadding;
  final double verticalPadding;
  final double blurSigma;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
