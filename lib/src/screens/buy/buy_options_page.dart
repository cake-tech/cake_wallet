import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
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

    return ScrollableWithBottomSection(
      content: Container(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 330),
            child: Column(
              children: [
                ...availableProviders.map((provider) {
                  return Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OptionTile(
                      imagePath: isLightMode ? provider.lightIcon : provider.darkIcon,
                      title: provider.toString(),
                      subTitle: provider.providerDescription,
                      onPressed: () => provider.launchProvider(context, isBuyAction),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
      bottomSection: Padding(
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
    );
  }
}
