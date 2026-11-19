import "dart:math";

import "package:auto_size_text/auto_size_text.dart";

import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class CoinActionButton extends StatelessWidget {
  const CoinActionButton({
    required this.icon,
    required this.label,
    required this.action,
    super.key,
    this.gradientColors,
  });

  final Widget icon;
  final String label;
  final VoidCallback action;
  final List<Color>? gradientColors;

  static const sizeFactor = 0.16;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * sizeFactor;
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
                  colors: gradientColors ??
                      [
                        context.customColors.cardGradientColorPrimary,
                        context.customColors.cardGradientColorSecondary,
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
              padding: const EdgeInsets.only(top: 8),
              child: ExcludeSemantics(
                // Long translations (Tamil "பரிமாற்றம்", "ஸ்கேன் செய்யவும்")
                // were wider than the circle and pushed the row past the
                // screen edge; keep the caption inside the button's width.
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: effectiveSize + 12),
                  child: AutoSizeText(
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    // The "copied" confirmation is one long word in Tamil
                    // ("நகலெடுக்கப்பட்டது") and cannot wrap, so allow a deep
                    // shrink and never clip silently.
                    minFontSize: 6,
                    overflow: TextOverflow.ellipsis,
                    wrapWords: false,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    label,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
