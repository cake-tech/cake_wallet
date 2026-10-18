import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/anypay/select_recipient_network_sheet.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

class EvmAddressDetectedSheet extends StatelessWidget {
  const EvmAddressDetectedSheet({super.key, required this.networks});

  final List<RecipientNetworkItem> networks;

  static Future<int?> show({
    required BuildContext context,
    required List<RecipientNetworkItem> networks,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EvmAddressDetectedSheet(networks: networks),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: colors.surface,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            ModalTopBar(
              title: "",
              trailingIcon: const Icon(Icons.close),
              onTrailingPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 32),
            StackedNetworkIcons(iconPaths: networks.map((n) => n.iconPath).toList()),
            const SizedBox(height: 24),
            Text(
              S.of(context).evm_address_detected,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.1),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                S.of(context).select_recipient_network_for_tx,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: -0.07),
              ),
            ),
            const SizedBox(height: 64),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NetworkListCard(
                  rows: [
                    for (final network in networks)
                      RecipientNetworkListRow(
                        item: network,
                        imageOverride: network.chainBadgeIconPath,
                        onTap: () => Navigator.of(context).pop(network.chainId),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class StackedNetworkIcons extends StatelessWidget {
  const StackedNetworkIcons({
    required this.iconPaths,
    this.size = 50,
    this.step = 34,
  });

  final List<String> iconPaths;
  final double size;
  final double step;

  @override
  Widget build(BuildContext context) {
    if (iconPaths.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final width = size + (iconPaths.length - 1) * step;

    return SizedBox(
      height: size,
      width: width,
      child: Stack(
        children: [
          for (int i = 0; i < iconPaths.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceContainer,
                  border: Border.all(color: colors.surface, width: 2),
                ),
                child: CakeImageWidget(imageUrl: iconPaths[i], fit: BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }
}
