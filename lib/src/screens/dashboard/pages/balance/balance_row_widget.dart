import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/exchange_trade/information_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class BalanceRowWidget extends StatelessWidget {
  BalanceRowWidget({
    required this.availableBalanceLabel,
    required this.availableBalance,
    required this.availableFiatBalance,
    required this.additionalBalanceLabel,
    required this.additionalBalance,
    required this.additionalFiatBalance,
    required this.secondAvailableBalanceLabel,
    required this.secondAvailableBalance,
    required this.secondAvailableFiatBalance,
    required this.secondAdditionalBalanceLabel,
    required this.secondAdditionalBalance,
    required this.secondAdditionalFiatBalance,
    required this.frozenBalance,
    required this.frozenFiatBalance,
    required this.currency,
    required this.hasAdditionalBalance,
    required this.hasSecondAvailableBalance,
    required this.hasSecondAdditionalBalance,
    required this.isTestnet,
    required this.dashboardViewModel,
    super.key,
  });

  final String availableBalanceLabel;
  final String availableBalance;
  final String availableFiatBalance;
  final String additionalBalanceLabel;
  final String additionalBalance;
  final String additionalFiatBalance;
  final String secondAvailableBalanceLabel;
  final String secondAvailableBalance;
  final String secondAvailableFiatBalance;
  final String secondAdditionalBalanceLabel;
  final String secondAdditionalBalance;
  final String secondAdditionalFiatBalance;
  final String frozenBalance;
  final String frozenFiatBalance;
  final CryptoCurrency currency;
  final bool hasAdditionalBalance;
  final bool hasSecondAvailableBalance;
  final bool hasSecondAdditionalBalance;
  final bool isTestnet;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            gradient: LinearGradient(
          colors: [
            dashboardViewModel.isDarkTheme
                ? CustomThemeColors.cardGradientColorPrimaryDark
                : CustomThemeColors.cardGradientColorPrimaryLight,
                    dashboardViewModel.isDarkTheme
                ? CustomThemeColors.cardGradientColorSecondaryDark
                : CustomThemeColors.cardGradientColorSecondaryLight,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
          ),
          child: TextButton(
            onPressed: _showToast,
            onLongPress: () => dashboardViewModel.balanceViewModel.switchBalanceValue(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Container(
              margin: const EdgeInsets.only(
                top: 10,
                left: 12,
                right: 12,
                bottom: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: hasAdditionalBalance
                                ? () => _showBalanceDescription(
                                    context, S.of(context).available_balance_description)
                                : null,
                            child: Row(
                              children: [
                                Semantics(
                                  hint: 'Double tap to see more information',
                                  container: true,
                                  child: Text(
                                    '${availableBalanceLabel}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          height: 1,
                                        ),
                                  ),
                                ),
                                if (hasAdditionalBalance)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(
                                      Icons.help_outline,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6),
                          AutoSizeText(
                            availableBalance,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  //fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                  height: 1,
                                ),
                            maxLines: 1,
                            textAlign: TextAlign.start,
                          ),
                          SizedBox(height: 6),
                          if (isTestnet)
                            Text(
                              S.of(context).testnet_coins_no_value,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1,
                                  ),
                            ),
                          if (!isTestnet)
                            Text(
                              '${availableFiatBalance}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    height: 1,
                                  ),
                            ),
                        ],
                      ),
                      SizedBox(
                        //width: min(MediaQuery.of(context).size.width * 0.2, 100),
                        child: Center(
                          child: Column(
                            children: [
                              CakeImageWidget(
                                imageUrl: currency.iconPath,
                                height: 40,
                                width: 40,
                                errorWidget: Container(
                                  height: 30.0,
                                  width: 30.0,
                                  child: Center(
                                    child: Text(
                                      currency.title.substring(0, min(currency.title.length, 2)),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                currency.title,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      height: 1,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (currency.isPotentialScam)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            S.of(context).potential_scam,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (frozenBalance.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 26),
                        Row(
                          children: [
                            Text(
                              S.of(context).frozen_balance,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    height: 1,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        AutoSizeText(
                          frozenBalance,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.primary,
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
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  height: 1,
                                ),
                          ),
                      ],
                    ),
                  if (hasAdditionalBalance)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24),
                        Text(
                          '${additionalBalanceLabel}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1,
                              ),
                        ),
                        SizedBox(height: 8),
                        AutoSizeText(
                          additionalBalance,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.secondary,
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
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  height: 1,
                                ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasSecondAdditionalBalance || hasSecondAvailableBalance) ...[
          SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  dashboardViewModel.isDarkTheme
                      ? CustomThemeColors.cardGradientColorPrimaryDark
                      : CustomThemeColors.cardGradientColorPrimaryLight,
                  dashboardViewModel.isDarkTheme
                      ? CustomThemeColors.cardGradientColorSecondaryDark
                      : CustomThemeColors.cardGradientColorSecondaryLight,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              // boxShadow: [
              //   BoxShadow(
              //       color: Theme.of(context)
              //           .extension<BalancePageTheme>()!
              //           .cardBorderColor
              //           .withAlpha(50),
              //       spreadRadius: dashboardViewModel.getShadowSpread(),
              //       blurRadius: dashboardViewModel.getShadowBlur())
              // ],
            ),
            child: TextButton(
              onPressed: _showToast,
              onLongPress: () => dashboardViewModel.balanceViewModel.switchBalanceValue(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, left: 12, right: 8, bottom: 10),
                    child: Stack(
                      children: [
                        if (currency == CryptoCurrency.ltc)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                child: Column(
                                  children: [
                                    Container(
                                      child: ImageIcon(
                                        AssetImage('assets/images/mweb_logo.png'),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'MWEB',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                            height: 1,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        if (hasSecondAvailableBalance)
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => launchUrl(
                                      Uri.parse(
                                          "https://docs.cakewallet.com/cryptos/litecoin#mweb"),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${secondAvailableBalanceLabel}',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color:
                                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                                height: 1,
                                              ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(
                                            Icons.help_outline,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  AutoSizeText(
                                    secondAvailableBalance,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context).colorScheme.onSurface,
                                          height: 1,
                                        ),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 6),
                                  if (!isTestnet)
                                    Text(
                                      '${secondAvailableFiatBalance}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            height: 1,
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 0, left: 24, right: 8, bottom: 16),
                    child: Stack(
                      children: [
                        if (hasSecondAdditionalBalance)
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 24),
                                  Text(
                                    '${secondAdditionalBalanceLabel}',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          height: 1,
                                        ),
                                  ),
                                  SizedBox(height: 8),
                                  AutoSizeText(
                                    secondAdditionalBalance,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontSize: 20,
                                          color: Theme.of(context).colorScheme.secondary,
                                          height: 1,
                                        ),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 4),
                                  if (!isTestnet)
                                    Text(
                                      '${secondAdditionalFiatBalance}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            height: 1,
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  IntrinsicHeight(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Semantics(
                              label: S.of(context).litecoin_mweb_pegin,
                              child: OutlinedButton(
                                onPressed: () {
                                  final mwebAddress =
                                      bitcoin!.getUnusedMwebAddress(dashboardViewModel.wallet);
                                  PaymentRequest? paymentRequest = null;
                                  if ((mwebAddress?.isNotEmpty ?? false)) {
                                    paymentRequest = PaymentRequest.fromUri(
                                        Uri.parse("litecoin:${mwebAddress}"));
                                  }
                                  Navigator.pushNamed(
                                    context,
                                    Routes.send,
                                    arguments: {
                                      'paymentRequest': paymentRequest,
                                      'coinTypeToSpendFrom': UnspentCoinType.nonMweb,
                                    },
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outlineVariant.withAlpha(0),
                                    width: 0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        height: 30,
                                        width: 30,
                                        'assets/images/received.png',
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        S.of(context).litecoin_mweb_pegin,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Semantics(
                              label: S.of(context).litecoin_mweb_pegout,
                              child: OutlinedButton(
                                onPressed: () {
                                  final litecoinAddress =
                                      bitcoin!.getUnusedSegwitAddress(dashboardViewModel.wallet);
                                  PaymentRequest? paymentRequest = null;
                                  if ((litecoinAddress?.isNotEmpty ?? false)) {
                                    paymentRequest = PaymentRequest.fromUri(
                                        Uri.parse("litecoin:${litecoinAddress}"));
                                  }
                                  Navigator.pushNamed(
                                    context,
                                    Routes.send,
                                    arguments: {
                                      'paymentRequest': paymentRequest,
                                      'coinTypeToSpendFrom': UnspentCoinType.mweb,
                                    },
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outlineVariant.withAlpha(0),
                                    width: 0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        height: 30,
                                        width: 30,
                                        'assets/images/upload.png',
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        S.of(context).litecoin_mweb_pegout,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  //  double getShadowSpread(){
  //   double spread = 3;
  //   else if (!dashboardViewModel.settingsStore.currentTheme.isDark) spread = 3;
  //   else if (dashboardViewModel.settingsStore.currentTheme.isDark) spread = 1;
  //   return spread;
  // }
  //
  //
  // double getShadowBlur(){
  //   double blur = 7;
  //   else if (dashboardViewModel.settingsStore.currentTheme.isDark) blur = 7;
  //   else if (dashboardViewModel.settingsStore.currentTheme.isDark) blur = 3;
  //   return blur;
  // }

  void _showBalanceDescription(BuildContext context, String content) {
    showPopUp<void>(context: context, builder: (_) => InformationPage(information: content));
  }

  void _showToast() async {
    try {
      await Fluttertoast.showToast(
        msg: S.current.show_balance_toast,
        backgroundColor: Color.fromRGBO(0, 0, 0, 0.85),
      );
    } catch (_) {}
  }
}
