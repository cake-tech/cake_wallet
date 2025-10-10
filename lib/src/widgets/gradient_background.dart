import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({required this.scaffold, super.key});

  final Widget scaffold;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            context.currentTheme.customColors.backgroundGradientColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: scaffold,
    );
  }
}
