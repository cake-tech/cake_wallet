import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/material.dart";

class RecipientNetworkSelector extends StatelessWidget {
  const RecipientNetworkSelector({
    super.key,
    required this.wallet,
    required this.onTap,
  });

  final WalletBase wallet;
  final void Function(ChainInfo currentChain) onTap;

  @override
  Widget build(BuildContext context) {
    if (evm == null) return const SizedBox.shrink();

    final currentChainId =
        evm!.getSelectedChainId(wallet) ?? evm!.getChainIdByWalletType(wallet.type);
    final currentChain = evm!.getChainInfoByChainId(currentChainId);
    if (currentChain == null) {
      printV("RecipientNetworkSelector: no chain info for chainId $currentChainId");
      return const SizedBox.shrink();
    }

    return _RecipientNetworkRow(
      networkName: currentChain.name,
      networkIconPath: symbolIconPathForWalletType(wallet.type) ?? "",
      onTap: () => onTap(currentChain),
    );
  }
}

class _RecipientNetworkRow extends StatelessWidget {
  const _RecipientNetworkRow({
    required this.networkName,
    required this.networkIconPath,
    required this.onTap,
  });

  final String networkName;
  final String networkIconPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).network_prefix_on,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: -0.07),
          ),
          const SizedBox(width: 12),
          CakeImageWidget(
            imageUrl: networkIconPath,
            width: 16,
            height: 16,
            fit: BoxFit.cover,
            color: isMonochromeSymbolIcon(networkIconPath) ? colors.primary : null,
          ),
          const SizedBox(width: 8),
          Text(
            networkName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.07,
                  color: colors.primary,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
