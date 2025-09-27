import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    required this.scaffold,
    required this.currentTheme,
    super.key,
  });

  final Widget scaffold;
  final MaterialThemeBase currentTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            currentTheme.customColors.backgroundGradientColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: scaffold,
    );
  }
}
