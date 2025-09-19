import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/cake_features_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';

class CakeFeaturesPage extends StatelessWidget {
  CakeFeaturesPage({required this.dashboardViewModel, required this.cakeFeaturesViewModel});

  final DashboardViewModel dashboardViewModel;
  final CakeFeaturesViewModel cakeFeaturesViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 24, top: 16),
            child: Text(
              'Cake ${S.of(context).features}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          Expanded(
            child: ListView(
              children: <Widget>[
                SizedBox(height: 2),
                DashBoardRoundedCardWidget(
                  currentTheme: dashboardViewModel.appStore.themeStore.currentTheme,
                  shadowBlur: dashboardViewModel.getShadowBlur(),
                  shadowSpread: dashboardViewModel.getShadowSpread(),
                  onTap: () {
                    if (Platform.isMacOS) {
                      _launchUrl("buy.cakepay.com");
                    } else {
                      _navigatorToGiftCardsPage(context);
                    }
                  },
                  title: 'Cake Pay',
                  subTitle: S.of(context).cake_pay_subtitle,
                  image: Image.asset(
                    'assets/images/cakepay.png',
                    height: 74,
                    width: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                Observer(builder: (_) {
                  if (dashboardViewModel.type == WalletType.ethereum) {
                    return DashBoardRoundedCardWidget(
                      currentTheme: dashboardViewModel.appStore.themeStore.currentTheme,
                      shadowBlur: dashboardViewModel.getShadowBlur(),
                      shadowSpread: dashboardViewModel.getShadowSpread(),
                      onTap: () => Navigator.of(context).pushNamed(Routes.dEuroSavings),
                      title: S.of(context).deuro_savings,
                      subTitle: S.of(context).deuro_savings_subtitle,
                      image: Image.asset(
                        'assets/images/deuro_icon.png',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  }

                  return const SizedBox();
                }),
                DashBoardRoundedCardWidget(
                  currentTheme: dashboardViewModel.appStore.themeStore.currentTheme,
                  shadowBlur: dashboardViewModel.getShadowBlur(),
                  shadowSpread: dashboardViewModel.getShadowSpread(),
                  onTap: () => _launchUrl("cake.nano-gpt.com"),
                  title: "NanoGPT",
                  subTitle: S.of(context).nanogpt_subtitle,
                  image: Image.asset(
                    'assets/images/nanogpt.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 125),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String url) {
    try {
      launchUrl(
        Uri.https(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      printV(e);
    }
  }

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
        Navigator.pushNamed(context, Routes.cakePayCardsPage);
    }
  }
}
