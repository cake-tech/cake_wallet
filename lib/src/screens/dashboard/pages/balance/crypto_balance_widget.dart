import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/balance/balance_row_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/home_screen_account_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/info_card.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
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
        return "assets/new-ui/hardware_wallets/device_bitbox.svg";
      case HardwareWalletType.ledger:
        return "assets/new-ui/hardware_wallets/device_ledger_nano_x.svg";
      case HardwareWalletType.trezor:
        return "assets/new-ui/hardware_wallets/device_trezor_safe_5.svg";
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
              return Container();
            },
          ),
          Observer(
            builder: (_) {
              return Container();
            },
          ),
          Observer(
              builder: (_) => dashboardViewModel.balanceViewModel.hasAccounts
                  ? HomeScreenAccountWidget(
                      walletName: dashboardViewModel.name, accountName: "")
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
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface,
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
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  if (dashboardViewModel
                                      .balanceViewModel.isHomeScreenSettingsEnabled)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                          minimumSize: Size(50, 30),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          alignment: Alignment.centerLeft),
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        Routes.homeSettings,
                                        arguments: dashboardViewModel.balanceViewModel,
                                      ),
                                      child: Container(
                                        child: SvgPicture.asset(
                                            'assets/images/home_screen_setting_icon.svg',
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              if (dashboardViewModel.balanceViewModel.isShowCard && FeatureFlag.isCakePayEnabled) {
                return IntroducingCard(
                    title: S.of(context).introducing_cake_pay,
                    subTitle: S.of(context).cake_pay_learn_more,
                    borderColor: Theme.of(context).colorScheme.outline,
                    closeCard: dashboardViewModel.balanceViewModel.disableIntroCakePayCard);
              }
              return Container();
            },
          ),
          Observer(builder: (_) {
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
              if (dashboardViewModel.balanceViewModel.formattedBalances.isEmpty) {
                return Center(
                  child: Container(
                    child: Text(
                      'Loading balances...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                separatorBuilder: (_, __) => Container(padding: EdgeInsets.only(bottom: 10)),
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
                          dashboardViewModel.balanceViewModel.hasAdditionalBalance(balance.asset),
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
              ],
            );
          }),
          SizedBox(height: 130),
        ],
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



}
