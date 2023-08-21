import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
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
                .extension<DashboardPageTheme>()!
                .firstGradientBackgroundColor,
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .secondGradientBackgroundColor,
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .thirdGradientBackgroundColor,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        )),
        child: scaffold);
  }
}
