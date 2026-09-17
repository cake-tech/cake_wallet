import 'dart:math';

import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CoinActionButton extends StatelessWidget {
  const CoinActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.action,
  });

  final Widget icon;
  final String label;
  final VoidCallback action;

  static const sizeFactor = 0.16;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * sizeFactor;
    final double effectiveSize = min(size, 80);

    // The caption below the circle is the accessible name, so it is excluded
    // from the semantics tree to keep this a single button node.
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: label,
        child: Column(
          children: [
            Container(
              width: effectiveSize,
              height: effectiveSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    context.customColors.cardGradientColorPrimary,
                    context.customColors.cardGradientColorSecondary
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  width: 1,
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  action();
                },
                icon: ExcludeSemantics(child: icon),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ExcludeSemantics(
                child: Text(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
