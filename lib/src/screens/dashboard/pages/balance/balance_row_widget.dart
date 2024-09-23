import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange_trade/information_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class BalanceRowWidget extends StatelessWidget {
  BalanceRowWidget({
    required this.availableBalanceLabel,
    required this.availableBalance,
    required this.availableFiatBalance,
    required this.additionalBalanceLabel,
    required this.additionalBalance,
    required this.additionalFiatBalance,
    required this.frozenBalance,
    required this.frozenFiatBalance,
    required this.currency,
    required this.hasAdditionalBalance,
    required this.isTestnet,
    super.key,
  });

  final String availableBalanceLabel;
  final String availableBalance;
  final String availableFiatBalance;
  final String additionalBalanceLabel;
  final String additionalBalance;
  final String additionalFiatBalance;
  final String frozenBalance;
  final String frozenFiatBalance;
  final CryptoCurrency currency;
  final bool hasAdditionalBalance;
  final bool isTestnet;

  // void _showBalanceDescription(BuildContext context) {
  //   showPopUp<void>(
  //     context: context,
  //     builder: (_) =>
  //         InformationPage(information: S.current.available_balance_description),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(
          color: Theme.of(context).extension<BalancePageTheme>()!.cardBorderColor,
          width: 1,
        ),
        color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 16, left: 24, right: 8, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasAdditionalBalance
                      ? () =>
                          _showBalanceDescription(context, S.current.available_balance_description)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Semantics(
                            hint: 'Double tap to see more information',
                            container: true,
                            child: Text('${availableBalanceLabel}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context)
                                        .extension<BalancePageTheme>()!
                                        .labelTextColor,
                                    height: 1)),
                          ),
                          if (hasAdditionalBalance)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.help_outline,
                                  size: 16,
                                  color: Theme.of(context)
                                      .extension<BalancePageTheme>()!
                                      .labelTextColor),
                            ),
                        ],
                      ),
                      SizedBox(height: 6),
                      AutoSizeText(availableBalance,
                          style: TextStyle(
                              fontSize: 24,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context)
                                  .extension<BalancePageTheme>()!
                                  .balanceAmountColor,
                              height: 1),
                          maxLines: 1,
                          textAlign: TextAlign.start),
                      SizedBox(height: 6),
                      if (isTestnet)
                        Text(S.current.testnet_coins_no_value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).extension<BalancePageTheme>()!.textColor,
                                height: 1)),
                      if (!isTestnet)
                        Text('${availableFiatBalance}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).extension<BalancePageTheme>()!.textColor,
                                height: 1)),
                    ],
                  ),
                ),
                SizedBox(
                  width: min(MediaQuery.of(context).size.width * 0.2, 100),
                  child: Center(
                    child: Column(
                      children: [
                        CakeImageWidget(
                          imageUrl: currency.iconPath,
                          height: 40,
                          width: 40,
                          displayOnError: Container(
                            height: 30.0,
                            width: 30.0,
                            child: Center(
                              child: Text(
                                currency.title.substring(0, min(currency.title.length, 2)),
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currency.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).extension<BalancePageTheme>()!.assetTitleColor,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (frozenBalance.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: hasAdditionalBalance
                    ? () =>
                        _showBalanceDescription(context, S.current.unavailable_balance_description)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 26),
                    Row(
                      children: [
                        Text(
                          S.current.frozen_balance,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.help_outline,
                              size: 16,
                              color:
                                  Theme.of(context).extension<BalancePageTheme>()!.labelTextColor),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    AutoSizeText(
                      frozenBalance,
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).extension<BalancePageTheme>()!.balanceAmountColor,
                        height: 1,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    if (!isTestnet)
                      Text(
                        frozenFiatBalance,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).extension<BalancePageTheme>()!.textColor,
                          height: 1,
                        ),
                      ),
                  ],
                ),
              ),
            if (hasAdditionalBalance)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),
                  Text(
                    '${additionalBalanceLabel}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  AutoSizeText(
                    additionalBalance,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).extension<BalancePageTheme>()!.assetTitleColor,
                      height: 1,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  if (!isTestnet)
                    Text(
                      '${additionalFiatBalance}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).extension<BalancePageTheme>()!.textColor,
                        height: 1,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showBalanceDescription(BuildContext context, String content) {
    showPopUp<void>(context: context, builder: (_) => InformationPage(information: content));
  }
}
