import 'dart:ui';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';

class AlertBackground extends StatelessWidget {
  const AlertBackground({Key? key, required this.child, this.dismissible = false});

  final Widget child;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: dismissible ? () => Navigator.of(context).pop() : null,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withAlpha(200)),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
