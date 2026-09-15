import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/l2_action_wallet_selector.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_info.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class SwitchNetworkWalletPage extends StatelessWidget {
  const SwitchNetworkWalletPage({
    required this.wallets,
    required this.networkName,
    required this.destinationIconPath,
    super.key,
  });

  final String networkName;
  final String destinationIconPath;
  final List<WalletInfo> wallets;

  static Future<WalletInfo?> push({
    required BuildContext context,
    required String networkName,
    required String targetIconPath,
    required List<WalletInfo> wallets,
  }) =>
      Navigator.of(context).push<WalletInfo>(
        CupertinoPageRoute(
          builder: (_) => SwitchNetworkWalletPage(
            networkName: networkName,
            destinationIconPath: targetIconPath,
            wallets: wallets,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ModalTopBar(
              title: "",
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 124),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward, color: colors.primary, size: 32),
                const SizedBox(width: 8),
                CakeImageWidget(
                  imageUrl: destinationIconPath,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  color: isMonochromeSymbolIcon(destinationIconPath) ? colors.primary : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).switch_to_x_wallet(networkName),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.1),
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).select_compatible_wallet,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: -0.07),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: wallets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final wallet = wallets[index];
                  return WalletRow(
                    currencyIconPath: getCryptoCurrencyIconForWalletListItem(wallet.type),
                    walletName: wallet.name,
                    onTap: () => Navigator.of(context).pop(wallet),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
