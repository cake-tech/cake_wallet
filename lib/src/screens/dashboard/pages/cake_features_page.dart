import 'package:cake_wallet/src/widgets/dashboard_card_widget.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/cake_features_view_model.dart';
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
                      onTap: () => _launchUrl("buy.cakepay.com"),
                      title: S.of(context).cake_pay_web_cards_title,
                      subTitle: S.of(context).cake_pay_web_cards_subtitle,
                      svgPicture: SvgPicture.asset(
                        'assets/images/cards.svg',
                        height: 125,
                        width: 125,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 10),
                    DashBoardRoundedCardWidget(
                      title: "NanoGPT",
                      subTitle: S.of(context).nanogpt_subtitle,
                      onTap: () => _launchUrl("cake.nano-gpt.com"),
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

  void _launchUrl(String url) {
    try {
      launchUrl(
        Uri.https(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }
}
