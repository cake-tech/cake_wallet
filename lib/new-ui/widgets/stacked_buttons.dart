import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:flutter/material.dart";

class StackedButtons extends StatelessWidget {
  const StackedButtons({
    required this.primaryText,
    required this.onPrimary,
    required this.secondaryText,
    required this.onSecondary,
    this.secondaryAsLink = false,
    this.primaryKey,
    this.secondaryKey,
    super.key,
  });

  final String primaryText;
  final VoidCallback onPrimary;
  final String secondaryText;
  final VoidCallback onSecondary;
  final bool secondaryAsLink;
  final Key? primaryKey;
  final Key? secondaryKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NewPrimaryButton(
          key: primaryKey,
          onPressed: onPrimary,
          text: primaryText,
          color: colors.primary,
          textColor: colors.onPrimary,
        ),
        if (secondaryAsLink) ...[
          const SizedBox(height: 9),
          TextButton(
            key: secondaryKey,
            onPressed: onSecondary,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              secondaryText,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    letterSpacing: -0.07,
                  ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          NewPrimaryButton(
            key: secondaryKey,
            onPressed: onSecondary,
            text: secondaryText,
            color: colors.surfaceContainer,
            textColor: colors.primary,
          ),
        ],
      ],
    );
  }
}
