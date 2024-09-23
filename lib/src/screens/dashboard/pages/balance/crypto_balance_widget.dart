import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/balance/balance_row_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/home_screen_account_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/src/widgets/introducing_card.dart';
import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';

class CryptoBalanceWidget extends StatelessWidget {
  const CryptoBalanceWidget({required this.dashboardViewModel, super.key});

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
                                          'assets/images/ledger_nano.png',
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
                  title: S.current.rep_warning,
                  subTitle: S.current.rep_warning_sub,
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
                  ]
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
}
