import 'package:cake_wallet/buy/onramper/onramper_buy_provider.dart';
import 'package:cake_wallet/buy/robinhood/robinhood_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:flutter/material.dart';

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
    final isLightMode = Theme.of(context).extension<OptionTileTheme>()?.useDarkImage ?? false;
    final iconRobinhood =
        Image.asset(isLightMode ? iconLightRobinhood : iconDarkRobinhood, height: 40, width: 40);
    final iconOnramper =
        Image.asset(isLightMode ? iconLightOnramper : iconDarkOnramper, height: 40, width: 40);

    return Container(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 330),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: OptionTile(
                  image: iconOnramper,
                  title: "Onramper",
                  description: S.of(context).onramper_option_description,
                  onPressed: () async =>
                      await getIt.get<OnRamperBuyProvider>().launchProvider(context),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: OptionTile(
                  image: iconRobinhood,
                  title: "Robinhood Connect",
                  description: S.of(context).robinhood_option_description,
                  onPressed: () async =>
                  await getIt.get<RobinhoodBuyProvider>().launchProvider(context),
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Text(
                  S.of(context).select_buy_provider_notice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
