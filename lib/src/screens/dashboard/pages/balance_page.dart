import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_listing_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/home_screen_account_widget.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/screens/exchange_trade/information_page.dart';
import 'package:cake_wallet/src/widgets/introducing_card.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BalancePage extends StatelessWidget {
  BalancePage({
    required this.dashboardViewModel,
    required this.settingsStore,
    required this.nftViewModel,
  });

  final DashboardViewModel dashboardViewModel;
  final NFTViewModel nftViewModel;
  final SettingsStore settingsStore;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final isEVMCompatible = isEVMCompatibleChain(dashboardViewModel.type);
        return DefaultTabController(
          length: isEVMCompatible ? 2 : 1,
          child: Column(
            children: [
              if (isEVMCompatible)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.label,
                      isScrollable: true,
                      physics: NeverScrollableScrollPhysics(),
                      labelStyle: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                        height: 1,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                        height: 1,
                      ),
                      labelColor:
                          Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                      dividerColor:
                          Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                      indicatorColor:
                          Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                      unselectedLabelColor: Theme.of(context)
                          .extension<DashboardPageTheme>()!
                          .pageTitleTextColor
                          .withOpacity(0.5),
                      tabs: [
                        Tab(text: 'My Crypto'),
                        Tab(text: 'My NFTs'),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    CryptoBalanceWidget(dashboardViewModel: dashboardViewModel),
                    if (isEVMCompatible) NFTListingPage(nftViewModel: nftViewModel)
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CryptoBalanceWidget extends StatelessWidget {
  const CryptoBalanceWidget({
    super.key,
    required this.dashboardViewModel,
  });

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => dashboardViewModel.balanceViewModel.isReversing =
          !dashboardViewModel.balanceViewModel.isReversing,
      onLongPressUp: () => dashboardViewModel.balanceViewModel.isReversing =
          !dashboardViewModel.balanceViewModel.isReversing,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Observer(
                builder: (_) => dashboardViewModel.balanceViewModel.hasAccounts
                    ? HomeScreenAccountWidget(
                        walletName: dashboardViewModel.name,
                        accountName: dashboardViewModel.subname)
                    : Column(
                        children: [
                          SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.only(left: 24, bottom: 16),
                            child: Observer(
                              builder: (_) {
                                return Row(
                                  children: [
                                    Text(
                                      dashboardViewModel.balanceViewModel.asset,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .extension<DashboardPageTheme>()!
                                            .pageTitleTextColor,
                                        height: 1,
                                      ),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (dashboardViewModel
                                        .balanceViewModel.isHomeScreenSettingsEnabled)
                                      InkWell(
                                        onTap: () => Navigator.pushNamed(
                                            context, Routes.homeSettings,
                                            arguments: dashboardViewModel.balanceViewModel),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Image.asset(
                                            'assets/images/home_screen_settings_icon.png',
                                            color: Theme.of(context)
                                                .extension<DashboardPageTheme>()!
                                                .pageTitleTextColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      )),
            Observer(
              builder: (_) {
                if (dashboardViewModel.balanceViewModel.isShowCard &&
                    FeatureFlag.isCakePayEnabled) {
                  return IntroducingCard(
                      title: S.of(context).introducing_cake_pay,
                      subTitle: S.of(context).cake_pay_learn_more,
                      borderColor: Theme.of(context).extension<BalancePageTheme>()!.cardBorderColor,
                      closeCard: dashboardViewModel.balanceViewModel.disableIntroCakePayCard);
                }
                return Container();
              },
            ),
            Observer(
              builder: (_) {
                return ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => Container(padding: EdgeInsets.only(bottom: 8)),
                  itemCount: dashboardViewModel.balanceViewModel.formattedBalances.length,
                  itemBuilder: (__, index) {
                    final balance =
                        dashboardViewModel.balanceViewModel.formattedBalances.elementAt(index);
                    return BalanceRowWidget(
                      availableBalanceLabel:
                          '${dashboardViewModel.balanceViewModel.availableBalanceLabel}',
                      availableBalance: balance.availableBalance,
                      availableFiatBalance: balance.fiatAvailableBalance,
                      additionalBalanceLabel:
                          '${dashboardViewModel.balanceViewModel.additionalBalanceLabel}',
                      additionalBalance: balance.additionalBalance,
                      additionalFiatBalance: balance.fiatAdditionalBalance,
                      frozenBalance: balance.frozenBalance,
                      frozenFiatBalance: balance.fiatFrozenBalance,
                      currency: balance.asset,
                      hasAdditionalBalance:
                          dashboardViewModel.balanceViewModel.hasAdditionalBalance,
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

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
                          Text('${availableBalanceLabel}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context)
                                      .extension<BalancePageTheme>()!
                                      .labelTextColor,
                                  height: 1)),
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
                          S.current.unavailable_balance,
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
                        color: Theme.of(context)
                            .extension<BalancePageTheme>()!
                            .balanceAmountColor,
                        height: 1,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
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
