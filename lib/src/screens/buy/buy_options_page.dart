import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';

class BuySellOptionsPage extends BasePage {
  BuySellOptionsPage(this.dashboardViewModel, this.isBuyAction);

  final DashboardViewModel dashboardViewModel;
  final bool isBuyAction;

  @override
  String get title => isBuyAction ? S.current.buy : S.current.sell;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) {
    final isLightMode = Theme.of(context).extension<OptionTileTheme>()?.useDarkImage ?? false;
    final availableProviders = isBuyAction
        ? dashboardViewModel.availableBuyProviders
        : dashboardViewModel.availableSellProviders;

    return Container(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 330),
          child: Column(
            children: [
              ...availableProviders.map((provider) {
                final icon = Image.asset(
                  isLightMode ? provider.lightIcon : provider.darkIcon,
                  height: 40,
                  width: 40,
                );

                return Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: OptionTile(
                    image: icon,
                    title: provider.toString(),
                    description: provider.providerDescription,
                    onPressed: () => provider.launchProvider(context, isBuyAction),
                  ),
                );
              }).toList(),
              Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Text(
                  isBuyAction
                      ? S.of(context).select_buy_provider_notice
                      : S.of(context).select_sell_provider_notice,
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
