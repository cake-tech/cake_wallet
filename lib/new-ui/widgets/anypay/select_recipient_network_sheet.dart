import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:flutter/material.dart";

class RecipientNetworkItem {
  const RecipientNetworkItem({
    required this.chainId,
    required this.name,
    required this.iconPath,
    this.chainBadgeIconPath,
  });

  final int chainId;
  final String name;
  final String iconPath;
  final String? chainBadgeIconPath;
}

class SelectRecipientNetworkSheet extends StatelessWidget {
  const SelectRecipientNetworkSheet({
    super.key,
    required this.networks,
    required this.currentChainId,
  });

  final List<RecipientNetworkItem> networks;
  final int currentChainId;

  static Future<int?> show({
    required BuildContext context,
    required List<RecipientNetworkItem> networks,
    required int currentChainId,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectRecipientNetworkSheet(
        networks: networks,
        currentChainId: currentChainId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    RecipientNetworkItem? current;
    final compatible = <RecipientNetworkItem>[];
    for (final network in networks) {
      if (network.chainId == currentChainId && current == null) {
        current = network;
      } else {
        compatible.add(network);
      }
    }

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
            CakeImageWidget(
              imageUrl: "assets/new-ui/network_cube.svg",
              width: 75,
              height: 75,
              colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).select_recipient_network,
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
                S.of(context).select_recipient_network_description,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: -0.07),
              ),
            ),
            const SizedBox(height: 32),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (current != null) ...[
                      NetworkListCard(
                        rows: [
                          RecipientNetworkListRow(
                            item: current,
                            subtitle: S.of(context).current_network,
                            onTap: () => Navigator.of(context).pop(current!.chainId),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (compatible.isNotEmpty) ...[
                      Text(
                        S.of(context).compatible_networks,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: -0.06),
                      ),
                      const SizedBox(height: 12),
                      NetworkListCard(
                        rows: [
                          for (final network in compatible)
                            RecipientNetworkListRow(
                              item: network,
                              onTap: () => Navigator.of(context).pop(network.chainId),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkListCard extends StatelessWidget {
  const NetworkListCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colors.surfaceContainerHigh,
                indent: 48,
                endIndent: 12,
              ),
          ],
        ],
      ),
    );
  }
}

class RecipientNetworkListRow extends StatelessWidget {
  const RecipientNetworkListRow(
      {super.key, required this.item, required this.onTap, this.subtitle, this.imageOverride});

  final String? subtitle;
  final String? imageOverride;
  final VoidCallback onTap;
  final RecipientNetworkItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            CakeImageWidget(
              imageUrl: imageOverride ?? item.iconPath,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              color: isMonochromeSymbolIcon(imageOverride ?? item.iconPath) ? colors.primary : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w400, letterSpacing: -0.07),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant, letterSpacing: -0.06, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
