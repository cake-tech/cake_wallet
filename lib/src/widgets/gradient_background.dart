import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({required this.scaffold});

  final Widget scaffold;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).brightness == Brightness.dark
                ? CustomThemeColors.backgroundGradientColorDark
                : CustomThemeColors.backgroundGradientColorLight,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: scaffold,
    );
  }
}
