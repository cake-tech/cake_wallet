import 'dart:math';

import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class ReceiveInfoBox extends StatelessWidget {
  ReceiveInfoBox(
      {super.key,
      required this.iconPath,
      required this.message,
      required this.onDismissed,
      this.bottomWidget});

  /// [addressRotates] tells whether the address type currently selected on the
  /// receive page actually rotates. Most wallet types only ever expose rotating
  /// address types, so it defaults to true; Zcash also offers static types, for
  /// which the rotation notice would be wrong.
  static ReceiveInfoBox? forWalletType(WalletType type,
      {required VoidCallback onDismissed,
      required AutoGenerateSubaddressStatus autoGenerateSubaddressStatus,
      List<CryptoCurrency>? supportedCurrencies,
      bool addressRotates = true}) {
    switch (type) {
      case WalletType.nano:
        return null;
      case WalletType.ethereum:
      case WalletType.base:
      case WalletType.solana:
      case WalletType.arbitrum:
      case WalletType.tron:
      case WalletType.polygon:
      case WalletType.zano:
      case WalletType.bsc:
        if (autoGenerateSubaddressStatus == AutoGenerateSubaddressStatus.disabled) return null;
        return ReceiveInfoBox(
            iconPath: "",
            message: "${S.current.infobox_multichain} ${walletTypeToString(type)}",
            onDismissed: onDismissed,
            bottomWidget: InfoboxCurrencyRow(
              currencies: supportedCurrencies ?? [],
              chainIconPath:
                  "assets/new-ui/chain_badges/${walletTypeToString(type).toLowerCase()}.svg",
            ));
      default:
        if (autoGenerateSubaddressStatus == AutoGenerateSubaddressStatus.disabled) return null;
        if (!addressRotates) return null;
        return ReceiveInfoBox(
          iconPath: "assets/new-ui/info.svg",
          message: S.current.infobox_auto_address,
          onDismissed: onDismissed,
        );
    }
  }

  late final String iconPath;
  late final String message;
  final Widget? bottomWidget;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              if (iconPath.isNotEmpty)
                ExcludeSemantics(
                  child: CakeImageWidget(
                    imageUrl: iconPath,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
                  ),
                ),
              Flexible(
                child: Column(
                    spacing: 10,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w300),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (bottomWidget != null) bottomWidget!,
                          MergeSemantics(
                            child: Semantics(
                              button: true,
                              child: GestureDetector(
                                  onTap: onDismissed,
                                  child: Text(
                                    S.of(context).dismiss,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300),
                                  )),
                            ),
                          ),
                        ],
                      )
                    ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class InfoboxCurrencyRow extends StatelessWidget {
  const InfoboxCurrencyRow({super.key, required this.currencies, required this.chainIconPath});

  final String chainIconPath;
  final List<CryptoCurrency> currencies;

  static const overlap = 16.0;
  static const iconSize = 24.0;
  static const maxCurrencies = 4;
  static const iconBorder = 1.5;

  @override
  Widget build(BuildContext context) {
    final currenciesWithImage = currencies.where((item) => item.iconPath != null).toList();
    final currenciesLimited =
        currenciesWithImage.sublist(0, min(currenciesWithImage.length, maxCurrencies));

    final double stackWidth = iconSize + (overlap * (currenciesLimited.length));

    // Purely illustrative: the meaning ("receive any token on <chain>") is
    // carried by the infobox message text next to it.
    return ExcludeSemantics(
      child: Row(
        spacing: 8,
        children: [
          CakeImageWidget(
            imageUrl: chainIconPath,
            width: 20,
            height: 20,
            colorFilter:
                ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
          ),
          Container(
            height: 28,
            width: 1,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          SizedBox(
            height: iconSize + iconBorder * 2,
            width: stackWidth,
            child: Stack(
              children: [
                Positioned(
                  top: iconBorder,
                  left: overlap * currenciesLimited.length,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(9999999)),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white.withAlpha(128),
                    ),
                  ),
                ),
                ...currenciesLimited
                    .asMap()
                    .entries
                    .map((entry) => Positioned(
                          left: 16.0 * entry.key,
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    width: iconBorder),
                                borderRadius: BorderRadius.circular(9999999)),
                            child: TokenImageWidget(
                              imageUrl: entry.value.iconPath ?? '',
                              size: 24,
                            ),
                          ),
                        ))
                    .toList()
                    .reversed,
              ],
            ),
          )
        ],
      ),
    );
  }
}
