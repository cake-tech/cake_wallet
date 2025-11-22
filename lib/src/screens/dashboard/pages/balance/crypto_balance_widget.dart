import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/balance/balance_row_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/home_screen_account_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/info_card.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/src/widgets/evm_switcher.dart';
import 'package:cake_wallet/src/widgets/introducing_card.dart';
import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class CryptoBalanceWidget extends StatelessWidget {
  const CryptoBalanceWidget({
    super.key,
    required this.dashboardViewModel,
  });

  final DashboardViewModel dashboardViewModel;
  final btcLockLight = 'assets/images/btc_lock_light.png';
  final btcLockDark = 'assets/images/btc_lock_dark.png';

  String? get hardwareWalletIcon {
    switch (dashboardViewModel.wallet.hardwareWalletType) {
      case null:
        return null;
      case HardwareWalletType.bitbox:
        return "assets/images/hardware_wallet/device_bitbox.svg";
      case HardwareWalletType.ledger:
        return "assets/images/hardware_wallet/device_ledger_nano_x.svg";
      case HardwareWalletType.trezor:
        return "assets/images/hardware_wallet/device_trezor_safe_5.svg";
      case HardwareWalletType.cupcake:
        return "assets/images/cupcake.svg";
      case HardwareWalletType.coldcard:
      case HardwareWalletType.seedsigner:
      case HardwareWalletType.keystone:
        return "assets/images/hardware_wallet/device_qr.svg";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  ),
                );
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          height: 1,
                                        ),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                  if (hardwareWalletIcon != null)
                                    Container(
                                      child: SvgPicture.asset(
                                        hardwareWalletIcon!,
                                        width: 24,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  if (dashboardViewModel.balanceViewModel
                                      .isHomeScreenSettingsEnabled)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          minimumSize: Size(50, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          alignment: Alignment.centerLeft),
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        Routes.homeSettings,
                                        arguments:
                                            dashboardViewModel.balanceViewModel,
                                      ),
                                      child: Container(
                                        child: SvgPicture.asset(
                                            'assets/images/home_screen_setting_icon.svg',
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            height: 30),
                                      ),
                                    ),
                                  if (dashboardViewModel
                                      .balanceViewModel.isEVMCompatible)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          minimumSize: Size(50, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          alignment: Alignment.centerLeft),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => EvmSwitcher(),
                                      ),
                                      child: Container(
                                        child: SvgPicture.asset(
                                            'assets/images/evm_switcher.svg',
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            height: 30),
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
                    borderColor: Theme.of(context).colorScheme.outline,
                    closeCard: dashboardViewModel
                        .balanceViewModel.disableIntroCakePayCard);
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
                separatorBuilder: (_, __) =>
                    Container(padding: EdgeInsets.only(bottom: 10)),
                itemCount: dashboardViewModel
                    .balanceViewModel.formattedBalances.length,
                itemBuilder: (__, index) {
                  final balance = dashboardViewModel
                      .balanceViewModel.formattedBalances
                      .elementAt(index);
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
                      hasAdditionalBalance: dashboardViewModel.balanceViewModel
                          .hasAdditionalBalance(balance.asset),
                      hasSecondAdditionalBalance: dashboardViewModel
                          .balanceViewModel.hasSecondAdditionalBalance,
                      hasSecondAvailableBalance: dashboardViewModel
                          .balanceViewModel.hasSecondAvailableBalance,
                      secondAdditionalBalance: balance.secondAdditionalBalance,
                      secondAdditionalFiatBalance:
                          balance.fiatSecondAdditionalBalance,
                      secondAvailableBalance: balance.secondAvailableBalance,
                      secondAvailableFiatBalance:
                          balance.fiatSecondAvailableBalance,
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
                if (dashboardViewModel
                    .isMoneroWalletBrokenReasons.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: DashBoardRoundedCardWidget(
                        customBorder: 30,
                        title: "This wallet has encountered an issue",
                        subTitle: "Here are the things that you should note:\n - " +
                            dashboardViewModel.isMoneroWalletBrokenReasons
                                .join("\n - ") +
                            "\n\nPlease restart your wallet and if it doesn't help contact our support.",
                      ))
                ],
                if (dashboardViewModel.showSilentPaymentsCard) ...[
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: DashBoardRoundedCardWidget(
                      shadowBlur: dashboardViewModel.getShadowBlur(),
                      shadowSpread: dashboardViewModel.getShadowSpread(),
                      marginV: 0,
                      marginH: 0,
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
                                      "https://docs.cakewallet.com/cryptos/bitcoin#silent-payments"),
                                  mode: LaunchMode.externalApplication,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      S.of(context).what_is_silent_payments,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            height: 1,
                                          ),
                                      softWrap: true,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Icon(
                                        Icons.help_outline,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Observer(
                                builder: (_) => StandardSwitch(
                                  value: dashboardViewModel
                                      .silentPaymentsScanningActive,
                                  onTapped: () =>
                                      _toggleSilentPaymentsScanning(context),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _toggleSilentPaymentsScanning(context),
                      image: !context.currentTheme.isDark
                          ? Image.asset(btcLockLight, height: 48)
                          : Image.asset(btcLockDark, height: 48),
                    ),
                  ),
                ],
                if (dashboardViewModel.showMwebCard) ...[
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: InfoCard(
                      title: S.of(context).litecoin_mweb,
                      description: S.of(context).litecoin_mweb_description,
                      leftButtonTitle: S.of(context).litecoin_mweb_dismiss,
                      rightButtonTitle: S.of(context).enable,
                      image: 'assets/images/mweb_logo.png',
                      leftButtonAction: () => _dismissMweb(context),
                      rightButtonAction: () => _enableMweb(context),
                      hintWidget: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => launchUrl(
                          Uri.parse(
                              "https://docs.cakewallet.com/cryptos/litecoin/#mweb"),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(
                          S.of(context).learn_more,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1,
                                  ),
                          softWrap: true,
                        ),
                      ),
                    ),
                  ),
                ],
                if (dashboardViewModel.showDecredInfoCard) ...[
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: InfoCard(
                      title: S.of(context).synchronizing,
                      description: S.of(context).decred_info_card_details,
                      image: 'assets/images/crypto/decred.webp',
                      leftButtonTitle: S.of(context).litecoin_mweb_dismiss,
                      rightButtonTitle: S.of(context).learn_more,
                      leftButtonAction: () =>
                          dashboardViewModel.dismissDecredInfoCard(),
                      rightButtonAction: () => launchUrl(Uri.parse(
                          "https://docs.cakewallet.com/cryptos/decred/#spv-sync")),
                    ),
                  ),
                ],
                if (dashboardViewModel.showPayjoinCard) ...[
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: InfoCard(
                      title: "Payjoin",
                      description: S.of(context).payjoin_card_content,
                      hintWidget: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => launchUrl(
                          Uri.parse(
                              "https://docs.cakewallet.com/cryptos/bitcoin/#payjoin"),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Row(
                          children: [
                            Text(
                              S.of(context).what_is_payjoin,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1,
                                  ),
                              softWrap: true,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.help_outline,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            )
                          ],
                        ),
                      ),
                      image: 'assets/images/payjoin.png',
                      leftButtonTitle: S.of(context).litecoin_mweb_dismiss,
                      rightButtonTitle: S.of(context).enable,
                      leftButtonAction: () =>
                          dashboardViewModel.dismissPayjoin(),
                      rightButtonAction: () => _enablePayjoin(context),
                    ),
                  ),
                ],
              ],
            );
          }),
          SizedBox(height: 130),
        ],
      ),
    );
  }

  Future<void> _toggleSilentPaymentsScanning(BuildContext context) async {
    final isSilentPaymentsScanningActive =
        dashboardViewModel.silentPaymentsScanningActive;
    final newValue = !isSilentPaymentsScanningActive;

    dashboardViewModel.silentPaymentsScanningActive = newValue;

    final needsToSwitch = !isSilentPaymentsScanningActive &&
        await bitcoin!.getNodeIsElectrsSPEnabled(dashboardViewModel.wallet) ==
            false;

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
                  dashboardViewModel.silentPaymentsScanningActive =
                      isSilentPaymentsScanningActive;
                  Navigator.of(context).pop();
                },
              ));
    }

    return dashboardViewModel.setSilentPaymentsScanning(newValue);
  }

  void _enablePayjoin(BuildContext context) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) => AlertWithOneAction(
              alertTitle: S.of(context).payjoin_enabling_popup_title,
              alertContent: S.of(context).payjoin_enabling_popup_content,
              buttonText: S.of(context).ok,
              buttonAction: () {
                Navigator.of(context).pop();
              },
            ));

    dashboardViewModel.enablePayjoin();
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
