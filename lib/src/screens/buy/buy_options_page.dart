import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyOptionsPage extends BasePage {
  final iconDarkRobinhood = 'assets/images/robinhood_dark.png';
  final iconLightRobinhood = 'assets/images/robinhood_light.png';
  final iconDarkOnramper = 'assets/images/onramper_dark.png';
  final iconLightOnramper = 'assets/images/onramper_light.png';

  @override
  String get title => S.current.buy;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconRobinhood =
        Image.asset(isDarkMode ? iconDarkRobinhood : iconLightRobinhood, height: 40, width: 40);
    final iconOnramper =
        Image.asset(isDarkMode ? iconDarkOnramper : iconLightOnramper, height: 40, width: 40);

    return Container(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 330),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: OptionTile(
                  image: iconRobinhood,
                  title: "Robinhood",
                  description: S.of(context).onramper_option_description,
                  onPressed: () {}, // ToDo: Generate ConnectId and Open Robinhood
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: OptionTile(
                  image: iconOnramper,
                  title: "Onramper",
                  description: S.of(context).onramper_option_description,
                  onPressed: () {}, // ToDo: Open OnRamper Widget
                ),
              ),
              Spacer(),
              Text(S.of(context).select_buy_provider_notice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {}
  }
}
