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
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.tertiary,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        )),
        child: scaffold);
  }
}
