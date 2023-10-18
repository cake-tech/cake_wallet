import 'package:cake_wallet/buy/robinhood/robinhood_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/exchange/moonpay/moonpay_exchange_provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:flutter/material.dart';

class ExchangeOptionsPage extends BasePage {
  final iconDarkRobinhood = 'assets/images/robinhood_dark.png';
  final iconLightRobinhood = 'assets/images/robinhood_light.png';
  final iconDarkOnramper = 'assets/images/onramper_dark.png';
  final iconLightOnramper = 'assets/images/onramper_light.png';

  @override
  String get title => S.current.exchange;

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
                  image: iconRobinhood,
                  title: "MoonPay Swaps",
                  description: S.of(context).moonpay_exchange_description,
                  onPressed: () async => await Navigator.of(context).pushReplacementNamed(Routes.exchange, arguments: ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: OptionTile(
                  image: iconOnramper,
                  title: "Normal Exchange",
                  description: S.of(context).normal_exchange_description,
                  onPressed: () async => await Navigator.of(context).pushReplacementNamed(Routes.exchange),
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Text(
                  S.of(context).select_exchange_provider_notice,
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
