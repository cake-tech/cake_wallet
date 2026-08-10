import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:flutter/material.dart";

class SendToNetworkPage extends StatelessWidget {
  const SendToNetworkPage({
    required this.title,
    required this.destinationNetworkName,
    required this.destinationIconPath,
    required this.currentNetworkName,
    required this.onSwitchWallet,
    required this.onSwap,
    super.key,
  });

  final String title;
  final String destinationNetworkName;
  final String destinationIconPath;
  final String currentNetworkName;
  final VoidCallback onSwitchWallet;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            ModalTopBar(
              title: "",
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context).maybePop(),
              trailingIcon: const Icon(Icons.close),
              trailingSemanticLabel: S.of(context).close,
              onTrailingPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CakeImageWidget(
                        imageUrl: destinationIconPath,
                        width: 75,
                        height: 75,
                        fit: BoxFit.contain,
                        color: isMonochromeSymbolIcon(destinationIconPath) ? colors.primary : null,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(context).send_to_network_description(
                              destinationNetworkName,
                              currentNetworkName,
                            ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: -0.07),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NewPrimaryButton(
                    onPressed: onSwitchWallet,
                    image: CakeImageWidget(
                      imageUrl: "assets/new-ui/wallet_filled.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(colors.onPrimary, BlendMode.srcIn),
                    ),
                    text: S.of(context).switch_to_x_wallet(destinationNetworkName),
                    color: colors.primary,
                    textColor: colors.onPrimary,
                  ),
                  const SizedBox(height: 12),
                  NewPrimaryButton(
                    onPressed: onSwap,
                    image: CakeImageWidget(
                      imageUrl: "assets/new-ui/swap_arrows.svg",
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                    ),
                    text: S.of(context).swap_from_network(currentNetworkName),
                    color: colors.surfaceContainer,
                    textColor: colors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
