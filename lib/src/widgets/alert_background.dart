import 'dart:ui';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class AlertBackground extends StatelessWidget {
  AlertBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration: BoxDecoration(color: PaletteDark.darkNightBlue.withOpacity(0.75)),
            child: Center(
              child: Container(
                width: ResponsiveLayoutUtil.kDesktopMaxWidthConstraint,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
