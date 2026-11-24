import 'package:cake_wallet/generated/i18n.dart';
import "package:cake_wallet/new-ui/widgets/animated_dropdown.dart";
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

typedef _Network = ({CryptoCurrency variant, WalletType? walletType});

class SelectNetworkPage extends StatelessWidget {
  const SelectNetworkPage({
    required this.assetTitle,
    required this.assetName,
    required this.assetIconPath,
    required this.variants,
    this.currentNetwork,
    super.key,
  });

  final String assetTitle;
  final String assetName;
  final String? assetIconPath;
  final List<CryptoCurrency> variants;
  final WalletType? currentNetwork;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final networks = [
      for (final variant in variants)
        (variant: variant, walletType: cryptoCurrencyOrTokenToWalletType(variant)),
    ];
    bool isCurrent(_Network n) => currentNetwork != null && n.walletType == currentNetwork;
    final nativeNetworks = [
      ...networks.where(isCurrent),
      ...networks.where((n) => n.walletType != null && !isCurrent(n)),
    ];
    final nonNativeNetworks = networks.where((n) => n.walletType == null).toList(growable: false);

    Widget networkList(List<_Network> group) => CurrencyPickerListContainer(
          rows: [
            for (final network in group)
              _NetworkRow(
                variant: network.variant,
                walletType: network.walletType,
                isCurrent: isCurrent(network),
                onTap: () => Navigator.of(context).pop(network.variant),
              ),
          ],
        );

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            ModalTopBar(
              testId: "select_network_page_top_bar",
              title: S.of(context).select_network_title,
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                children: [
                  // Illustration of the asset named by the title below it.
                  ExcludeSemantics(
                    child: Center(
                      child: CakeImageWidget(
                        imageUrl: assetIconPath,
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      text: "$assetName ",
                      children: [
                        TextSpan(
                          text: assetTitle,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      S.of(context).select_network_subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 32),
                  networkList(nativeNetworks.isEmpty ? nonNativeNetworks : nativeNetworks),
                  if (nativeNetworks.isNotEmpty && nonNativeNetworks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    AnimatedDropdown(
                      dropdownText: S.of(context).picker_more_networks,
                      content: networkList(nonNativeNetworks),
                    ),
                  ],
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
  const _NetworkRow({
    required this.variant,
    required this.walletType,
    required this.isCurrent,
    required this.onTap,
  });

  final CryptoCurrency variant;
  final WalletType? walletType;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final wt = walletType;
    final networkIconPath =
        wt != null ? getCryptoCurrencyIconForWalletListItem(wt) : variant.iconPath;
    final networkName = chainNameForCurrency(variant);
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: CakeImageWidget(
                    imageUrl: networkIconPath,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        networkName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (isCurrent)
                        Text(
                          S.of(context).current_network,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.primary),
                        ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
