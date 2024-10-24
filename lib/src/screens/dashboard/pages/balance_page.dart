import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_listing_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/home_screen_account_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/screens/exchange_trade/information_page.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/src/widgets/introducing_card.dart';
import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';

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
                      dividerColor: Colors.transparent,
                      indicatorColor:
                          Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                      unselectedLabelColor: Theme.of(context)
                          .extension<DashboardPageTheme>()!
                          .pageTitleTextColor
                          .withOpacity(0.5),
                      tabAlignment: TabAlignment.start,
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
              builder: (_) {
                if (dashboardViewModel.getMoneroError != null) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: DashBoardRoundedCardWidget(
                      title: "Invalid monero bindings",
                      subTitle: dashboardViewModel.getMoneroError.toString(),
                      onTap: () {},
                    ),
                  );
                }
                return Container();
              },
            ),
            Observer(
              builder: (_) {
                if (dashboardViewModel.getWowneroError != null) {
                  return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: DashBoardRoundedCardWidget(
                        title: "Invalid wownero bindings",
                        subTitle: dashboardViewModel.getWowneroError.toString(),
                        onTap: () {},
                      ));
                }
                return Container();
              },
            ),
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
                                    if (dashboardViewModel.wallet.isHardwareWallet)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.asset(
                                          'assets/images/hardware_wallet/ledger_nano_x.png',
                                          width: 24,
                                          color: Theme.of(context)
                                              .extension<DashboardPageTheme>()!
                                              .pageTitleTextColor,
                                        ),
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
            Observer(builder: (_) {
              if (!dashboardViewModel.showRepWarning) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DashBoardRoundedCardWidget(
                  title: S.of(context).rep_warning,
                  subTitle: S.of(context).rep_warning_sub,
                  onTap: () => Navigator.of(context).pushNamed(Routes.changeRep),
                  onClose: () {
                    dashboardViewModel.settingsStore.shouldShowRepWarning = false;
                  },
                ),
              );
            }),
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
                    return Observer(builder: (_) {
                      return BalanceRowWidget(
                        dashboardViewModel: dashboardViewModel,
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
                        hasSecondAdditionalBalance:
                            dashboardViewModel.balanceViewModel.hasSecondAdditionalBalance,
                        hasSecondAvailableBalance:
                            dashboardViewModel.balanceViewModel.hasSecondAvailableBalance,
                        secondAdditionalBalance: balance.secondAdditionalBalance,
                        secondAdditionalFiatBalance: balance.fiatSecondAdditionalBalance,
                        secondAvailableBalance: balance.secondAvailableBalance,
                        secondAvailableFiatBalance: balance.fiatSecondAvailableBalance,
                        secondAdditionalBalanceLabel:
                            '${dashboardViewModel.balanceViewModel.secondAdditionalBalanceLabel}',
                        secondAvailableBalanceLabel:
                            '${dashboardViewModel.balanceViewModel.secondAvailableBalanceLabel}',
                        isTestnet: dashboardViewModel.isTestnet,
                      );
                    });
                  },
                );
              },
            ),
            Observer(builder: (context) {
              return Column(
                children: [
                  if (dashboardViewModel.isMoneroWalletBrokenReasons.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: DashBoardRoundedCardWidget(
                          customBorder: 30,
                          title: "This wallet has encountered an issue",
                          subTitle: "Here are the things that you should note:\n - " +
                              dashboardViewModel.isMoneroWalletBrokenReasons.join("\n - ") +
                              "\n\nPlease restart your wallet and if it doesn't help contact our support.",
                          onTap: () {},
                        ))
                  ],
                  if (dashboardViewModel.showSilentPaymentsCard) ...[
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: DashBoardRoundedCardWidget(
                        customBorder: 30,
                        title: S.of(context).silent_payments,
                        subTitle: S.of(context).enable_silent_payments_scanning,
                        hint: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => launchUrl(
                                    Uri.parse(
                                        "https://guides.cakewallet.com/docs/cryptos/bitcoin/#silent-payments"),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        S.of(context).what_is_silent_payments,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.w400,
                                          color: Theme.of(context)
                                              .extension<BalancePageTheme>()!
                                              .labelTextColor,
                                          height: 1,
                                        ),
                                        softWrap: true,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.help_outline,
                                            size: 16,
                                            color: Theme.of(context)
                                                .extension<BalancePageTheme>()!
                                                .labelTextColor),
                                      )
                                    ],
                                  ),
                                ),
                                Observer(
                                  builder: (_) => StandardSwitch(
                                    value: dashboardViewModel.silentPaymentsScanningActive,
                                    onTaped: () => _toggleSilentPaymentsScanning(context),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _toggleSilentPaymentsScanning(context),
                        icon: Icon(
                          Icons.lock,
                          color:
                              Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                          size: 50,
                        ),
                      ),
                    ),
                  ],
                  if (dashboardViewModel.showMwebCard) ...[
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: DashBoardRoundedCardWidget(
                        customBorder: 30,
                        title: S.of(context).litecoin_mweb,
                        subTitle: S.of(context).litecoin_mweb_description,
                        hint: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => launchUrl(
                                Uri.parse(
                                    "https://guides.cakewallet.com/docs/cryptos/litecoin/#mweb"),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(
                                S.of(context).learn_more,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context)
                                      .extension<BalancePageTheme>()!
                                      .labelTextColor,
                                  height: 1,
                                ),
                                softWrap: true,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _dismissMweb(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                    ),
                                    child: Text(
                                      S.of(context).litecoin_mweb_dismiss,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _enableMweb(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: Text(
                                      S.of(context).enable,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => {},
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ImageIcon(
                            AssetImage('assets/images/mweb_logo.png'),
                            color: Color.fromARGB(255, 11, 70, 129),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSilentPaymentsScanning(BuildContext context) async {
    final isSilentPaymentsScanningActive = dashboardViewModel.silentPaymentsScanningActive;
    final newValue = !isSilentPaymentsScanningActive;

    dashboardViewModel.silentPaymentsScanningActive = newValue;

    final needsToSwitch = !isSilentPaymentsScanningActive &&
        await bitcoin!.getNodeIsElectrsSPEnabled(dashboardViewModel.wallet) == false;

    if (needsToSwitch) {
      return showPopUp<void>(
          context: context,
          builder: (BuildContext context) => AlertWithTwoActions(
                alertTitle: S.of(context).change_current_node_title,
                alertContent: S.of(context).confirm_silent_payments_switch_node,
                rightButtonText: S.of(context).confirm,
                leftButtonText: S.of(context).cancel,
                actionRightButton: () {
                  dashboardViewModel.setSilentPaymentsScanning(newValue);
                  Navigator.of(context).pop();
                },
                actionLeftButton: () {
                  dashboardViewModel.silentPaymentsScanningActive = isSilentPaymentsScanningActive;
                  Navigator.of(context).pop();
                },
              ));
    }

    return dashboardViewModel.setSilentPaymentsScanning(newValue);
  }

  Future<void> _enableMweb(BuildContext context) async {
    if (!dashboardViewModel.hasEnabledMwebBefore) {
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) => AlertWithOneAction(
                alertTitle: S.of(context).alert_notice,
                alertContent: S.of(context).litecoin_mweb_warning,
                buttonText: S.of(context).understand,
                buttonAction: () {
                  Navigator.of(context).pop();
                },
              ));
    }
    dashboardViewModel.setMwebEnabled();
  }

  Future<void> _dismissMweb(BuildContext context) async {
    await showPopUp<void>(
        context: context,
        builder: (BuildContext context) => AlertWithOneAction(
              alertTitle: S.of(context).alert_notice,
              alertContent: S.of(context).litecoin_mweb_enable_later,
              buttonText: S.of(context).understand,
              buttonAction: () {
                Navigator.of(context).pop();
              },
            ));
    dashboardViewModel.dismissMweb();
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

  // void _showBalanceDescription(BuildContext context) {
  //   showPopUp<void>(
  //     context: context,
  //     builder: (_) =>
  //         InformationPage(information: S.of(context).available_balance_description),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
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
                        ? () => _showBalanceDescription(
                            context, S.of(context).available_balance_description)
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
                          Text(S.of(context).testnet_coins_no_value,
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
                              color:
                                  Theme.of(context).extension<BalancePageTheme>()!.assetTitleColor,
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
                      ? () => _showBalanceDescription(
                          context, S.of(context).unavailable_balance_description)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 26),
                      Row(
                        children: [
                          Text(
                            S.of(context).unavailable_balance,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w400,
                              color:
                                  Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
                              height: 1,
                            ),
                          ),
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
                      SizedBox(height: 8),
                      AutoSizeText(
                        frozenBalance,
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w400,
                          color:
                              Theme.of(context).extension<BalancePageTheme>()!.balanceAmountColor,
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
      ),
      if (hasSecondAdditionalBalance || hasSecondAvailableBalance) ...[
        SizedBox(height: 16),
        Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 16, left: 24, right: 8, bottom: 16),
                  child: Stack(
                    children: [
                      if (currency == CryptoCurrency.ltc)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.only(right: 16, top: 0),
                              child: Column(
                                children: [
                                  Container(
                                    child: ImageIcon(
                                      AssetImage('assets/images/mweb_logo.png'),
                                      color: Theme.of(context)
                                          .extension<BalancePageTheme>()!
                                          .assetTitleColor,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'MWEB',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context)
                                          .extension<BalancePageTheme>()!
                                          .assetTitleColor,
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
                                        "https://guides.cakewallet.com/docs/cryptos/litecoin/#mweb"),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${secondAvailableBalanceLabel}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.w400,
                                          color: Theme.of(context)
                                              .extension<BalancePageTheme>()!
                                              .labelTextColor,
                                          height: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.help_outline,
                                            size: 16,
                                            color: Theme.of(context)
                                                .extension<BalancePageTheme>()!
                                                .labelTextColor),
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8),
                                AutoSizeText(
                                  secondAvailableBalance,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context)
                                        .extension<BalancePageTheme>()!
                                        .assetTitleColor,
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .extension<BalancePageTheme>()!
                                          .textColor,
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context)
                                        .extension<BalancePageTheme>()!
                                        .labelTextColor,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 8),
                                AutoSizeText(
                                  secondAdditionalBalance,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context)
                                        .extension<BalancePageTheme>()!
                                        .assetTitleColor,
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context)
                                          .extension<BalancePageTheme>()!
                                          .textColor,
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
                    padding: EdgeInsets.symmetric(horizontal: 24),
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
                                  paymentRequest =
                                      PaymentRequest.fromUri(Uri.parse("litecoin:${mwebAddress}"));
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
                                backgroundColor: Colors.grey.shade400
                                    .withAlpha(50),
                                side: BorderSide(color: Colors.grey.shade400
                                      .withAlpha(50), width: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
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
                                      color: Theme.of(context)
                                          .extension<BalancePageTheme>()!
                                          .balanceAmountColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      S.of(context).litecoin_mweb_pegin,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .extension<BalancePageTheme>()!
                                            .textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
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
                                backgroundColor: Colors.grey.shade400
                                    .withAlpha(50),
                                side: BorderSide(color: Colors.grey.shade400
                                      .withAlpha(50), width: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
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
                                      color: Theme.of(context)
                                          .extension<BalancePageTheme>()!
                                          .balanceAmountColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      S.of(context).litecoin_mweb_pegout,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .extension<BalancePageTheme>()!
                                            .textColor,
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
    ]);
  }

  void _showBalanceDescription(BuildContext context, String content) {
    showPopUp<void>(context: context, builder: (_) => InformationPage(information: content));
  }
}
