import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/wallet_network/network_page_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";

class AddEvmNetworksDisclaimerPage extends StatelessWidget {
  const AddEvmNetworksDisclaimerPage({super.key});

  static const _popularIconPaths = [
    "assets/new-ui/network_icons/optimism.svg",
    "assets/new-ui/network_icons/hyperliquid.svg",
    "assets/new-ui/network_icons/arc.svg",
    "assets/new-ui/network_icons/monad.svg",
    "assets/new-ui/network_icons/plasma.svg",
    "assets/new-ui/network_icons/ink.svg",
    "assets/new-ui/network_icons/xlayer.svg",
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodySmall?.copyWith(letterSpacing: -0.06);
    final buttonLabelStyle =
        textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.07);

    return NetworkPageScaffold(
      title: S.of(context).add_evm_networks,
      onBack: () => Navigator.of(context).pop(false),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CakeImageWidget(
                    imageUrl: "assets/new-ui/evm_network_add.svg",
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    S.of(context).evm_networks_disclaimer_opt_in,
                    textAlign: TextAlign.center,
                    style: bodyStyle?.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: 32),
                  const _PopularNetworksStrip(),
                  const SizedBox(height: 32),
                  Text(
                    S.of(context).evm_networks_disclaimer_scope,
                    textAlign: TextAlign.center,
                    style: bodyStyle?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          spacing: 24,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                S.of(context).evm_networks_disclaimer_notice,
                textAlign: TextAlign.center,
                style: bodyStyle?.copyWith(
                  color: context.customColors.warningOutlineColor,
                ),
              ),
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: NewPrimaryButton(
                    key: const ValueKey("add_evm_networks_disclaimer_cancel_button_key"),
                    onPressed: () => Navigator.of(context).pop(false),
                    text: S.of(context).cancel,
                    color: colors.surfaceContainer,
                    textColor: colors.primary,
                    labelStyle: buttonLabelStyle,
                  ),
                ),
                Expanded(
                  child: NewPrimaryButton(
                    key: const ValueKey(
                      "add_evm_networks_disclaimer_continue_button_key",
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    text: S.of(context).continue_text,
                    color: colors.primary,
                    textColor: colors.onPrimary,
                    labelStyle: buttonLabelStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularNetworksStrip extends StatelessWidget {
  const _PopularNetworksStrip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconRadius = BorderRadius.circular(7);

    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            for (final path in AddEvmNetworksDisclaimerPage._popularIconPaths)
              Container(
                width: 24,
                height: 24,
                foregroundDecoration: BoxDecoration(
                  borderRadius: iconRadius,
                  border: Border.all(color: colors.onSurface),
                ),
                child: ClipRRect(
                  borderRadius: iconRadius,
                  child: CakeImageWidget(imageUrl: path, width: 24, height: 24),
                ),
              ),
            const CakeImageWidget(
              imageUrl: "assets/new-ui/network_add_tile.svg",
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
