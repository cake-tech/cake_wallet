import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/market_place_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';

class MarketPlacePage extends StatelessWidget {
  MarketPlacePage({
    required this.dashboardViewModel,
    required this.marketPlaceViewModel,
  });

  final DashboardViewModel dashboardViewModel;
  final MarketPlaceViewModel marketPlaceViewModel;
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
                S.of(context).market_place,
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
                    ),
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
        marketPlaceViewModel.isIoniaUserAuthenticated().then((value) {
          if (value) {
            Navigator.pushNamed(context, Routes.ioniaManageCardsPage);
            return;
          }
          Navigator.of(context).pushNamed(Routes.ioniaWelcomePage);
        });
    }
  }
}
