import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/cake_features_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CakeFeaturesPage extends StatelessWidget {
  CakeFeaturesPage({
    required this.dashboardViewModel,
    required this.cakeFeaturesViewModel,
  });

  final DashboardViewModel dashboardViewModel;
  final CakeFeaturesViewModel cakeFeaturesViewModel;
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: RawScrollbar(
        thumbColor: Colors.white.withOpacity(0.15),
        radius: Radius.circular(20),
        thumbVisibility: true,
        thickness: 2,
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              Text(
                'Cake ${S.of(context).features}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  children: <Widget>[
                    // SizedBox(height: 20),
                    // DashBoardRoundedCardWidget(
                    //   onTap: () => launchUrl(
                    //     Uri.parse("https://cakelabs.com/news/cake-pay-mobile-to-shut-down/"),
                    //     mode: LaunchMode.externalApplication,
                    //   ),
                    //   title: S.of(context).cake_pay_title,
                    //   subTitle: S.of(context).cake_pay_subtitle,
                    // ),
                    SizedBox(height: 20),
                    DashBoardRoundedCardWidget(
                      onTap: () => launchUrl(
                        Uri.https("buy.cakepay.com"),
                        mode: LaunchMode.externalApplication,
                      ),
                      title: S.of(context).cake_pay_web_cards_title,
                      subTitle: S.of(context).cake_pay_web_cards_subtitle,
                      svgPicture: SvgPicture.asset(
                        'assets/images/cards.svg',
                        height: 125,
                        width: 125,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DashBoardRoundedCardWidget(
                      title: "NanoGPT",
                      subTitle: S.of(context).nanogpt_subtitle,
                      onTap: () => launchUrl(
                        Uri.https("cake.nano-gpt.com"),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                    if (dashboardViewModel.hasSilentPayments) ...[
                      SizedBox(height: 10),
                      DashBoardRoundedCardWidget(
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
                                    // TODO: Update URL
                                    Uri.https("guides.cakewallet.com"),
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
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TODO: Remove ionia flow/files if we will discard it
  void _navigatorToGiftCardsPage(BuildContext context) {
    final walletType = dashboardViewModel.type;

    switch (walletType) {
      case WalletType.haven:
        showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.of(context).error,
                  alertContent: S.of(context).gift_cards_unavailable,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            });
        break;
      default:
        cakeFeaturesViewModel.isIoniaUserAuthenticated().then((value) {
          if (value) {
            Navigator.pushNamed(context, Routes.ioniaManageCardsPage);
            return;
          }
          Navigator.of(context).pushNamed(Routes.ioniaWelcomePage);
        });
    }
  }

  Future<void> _toggleSilentPaymentsScanning(BuildContext context) async {
    final isSilentPaymentsScanningActive = dashboardViewModel.silentPaymentsScanningActive;
    final newValue = !isSilentPaymentsScanningActive;

    final needsToSwitch = bitcoin!.getNodeIsCakeElectrs(dashboardViewModel.wallet) == false;

    if (needsToSwitch) {
      return showPopUp<void>(
          context: context,
          builder: (BuildContext context) => AlertWithTwoActions(
                alertTitle: S.of(context).change_current_node_title,
                alertContent: S.of(context).confirm_silent_payments_switch_node,
                rightButtonText: S.of(context).ok,
                leftButtonText: S.of(context).cancel,
                actionRightButton: () {
                  dashboardViewModel.setSilentPaymentsScanning(newValue);
                  Navigator.of(context).pop();
                },
                actionLeftButton: () => Navigator.of(context).pop(),
              ));
    }

    return dashboardViewModel.setSilentPaymentsScanning(newValue);
  }
}
