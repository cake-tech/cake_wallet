import 'package:cake_wallet/themes/extensions/dashboard_gradient_theme.dart';
import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({required this.scaffold});

  final Widget scaffold;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [
            Theme.of(context)
                .extension<DashboardGradientTheme>()!
                .firstGradientColor,
            Theme.of(context)
                .extension<DashboardGradientTheme>()!
                .secondGradientColor,
            Theme.of(context)
                .extension<DashboardGradientTheme>()!
                .thirdGradientColor,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        )),
        child: scaffold);
  }
}
