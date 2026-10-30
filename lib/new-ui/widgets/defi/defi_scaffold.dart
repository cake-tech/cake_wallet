import "package:flutter/material.dart";

class DefiScaffold extends StatelessWidget {
  const DefiScaffold({required this.child, this.gradient = false, super.key});

  final Widget child;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: gradient ? null : colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        gradient: gradient
            ? LinearGradient(
                colors: [colorScheme.surface, colorScheme.surfaceDim],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
      ),
      child: SafeArea(child: child),
    );
  }
}
