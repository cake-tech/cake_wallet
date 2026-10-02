import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/evm_network.dart";
import "package:flutter/material.dart";

class SwapSectionHeader extends StatelessWidget {
  const SwapSectionHeader({
    required this.label,
    required this.networkName,
    required this.networkIconPath,
    this.addedNetworkChainId,
  });

  final String label;
  final String networkName;
  final String networkIconPath;

  final int? addedNetworkChainId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final addedNetwork = AddedNetworkCurrency.tryFromChainId(addedNetworkChainId);
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
            imageUrl: addedNetwork == null ? networkIconPath : addedNetwork.iconPath,
            width: 16,
            height: 16,
            color: isMonochromeSymbolIcon(networkIconPath) ? colors.primary : null,
            isRoundedSquare: addedNetwork != null,
            isOutlined: addedNetwork != null,
            fallbackName: addedNetwork?.fullName,
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
