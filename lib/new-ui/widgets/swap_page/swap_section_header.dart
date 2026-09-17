import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:flutter/material.dart";

class SwapSectionHeader extends StatelessWidget {
  const SwapSectionHeader({
    required this.label,
    required this.networkName,
    required this.networkIconPath,
  });

  final String label;
  final String networkName;
  final String networkIconPath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            label,
            style:
                textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -0.07),
          ),
          const SizedBox(width: 8),
          CakeImageWidget(
            imageUrl: networkIconPath,
            width: 16,
            height: 16,
            color: isMonochromeSymbolIcon(networkIconPath) ? colors.primary : null,
          ),
          const SizedBox(width: 4),
          Text(
            networkName,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: -0.07,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
