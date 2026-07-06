import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';

class RecipientNetworkItem {
  const RecipientNetworkItem({
    required this.chainId,
    required this.name,
    required this.iconPath,
  });

  final int chainId;
  final String name;
  final String iconPath;
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
            SizedBox(height: 32),
            ModalTopBar(
              title: '',
              trailingIcon: const Icon(Icons.close),
              onTrailingPressed: () => Navigator.of(context).maybePop(),
            ),
            Icon(
              Icons.view_in_ar_outlined,
              size: 75,
              color: colors.onSurfaceVariant,
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
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (current != null) ...[
                    CurrencyPickerListContainer(
                      rows: [
                        _NetworkRow(
                          item: current,
                          subtitle: S.of(context).current_network,
                          onTap: () => Navigator.of(context).pop(current!.chainId),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (compatible.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        S.of(context).compatible_networks,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                    CurrencyPickerListContainer(
                      rows: [
                        for (final network in compatible)
                          _NetworkRow(
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
          ],
        ),
      ),
    );
  }
}

class _NetworkRow extends StatelessWidget {
  const _NetworkRow({required this.item, required this.onTap, this.subtitle});

  final RecipientNetworkItem item;
  final String? subtitle;
  final VoidCallback onTap;

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
              imageUrl: item.iconPath,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: -0.06, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
