import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/exchange_trade/exchange_trade_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/palette.dart';

class TradeDetailsPage extends BasePage {

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  String get title => S.current.trade_details_title;

  @override
  Widget body(BuildContext context) {
    final exchangeStore = Provider.of<ExchangeTradeStore>(context);
    final settingsStore = Provider.of<SettingsStore>(context);
    final createdAtFormat = settingsStore.getCurrentDateFormat(
          formatUSA: "yyyy.MM.dd, HH:mm",
          formatDefault: "dd.MM.yyyy, HH:mm");

    return Container(
        color: PaletteDark.historyPanel,
        padding: EdgeInsets.only(top: 20, bottom: 20),
        child: Observer(builder: (_) {
          final trade = exchangeStore.trade;
          final items = [
            StandartListItem(
                title: S.of(context).trade_details_id, value: trade.id),
            StandartListItem(
                title: S.of(context).trade_details_state,
                value: trade.state != null
                    ? trade.state.toString()
                    : S.of(context).trade_details_fetching)
          ];

          if (trade.provider != null) {
            items.add(StandartListItem(
                title: S.of(context).trade_details_provider,
                value: trade.provider.toString()));
          }

          if (trade.createdAt != null) {
            items.add(StandartListItem(
                title: S.of(context).trade_details_created_at,
                value: createdAtFormat.format(trade.createdAt).toString()));
          }

          if (trade.from != null && trade.to != null) {
            items.add(StandartListItem(
                title: S.of(context).trade_details_pair,
                value: '${trade.from.toString()} → ${trade.to.toString()}'));
          }

          return ListView.separated(
              separatorBuilder: (_, __) => Container(
                height: 1,
                padding: EdgeInsets.only(left: 24),
                color: PaletteDark.menuList,
                child: Container(
                  height: 1,
                  color: PaletteDark.walletCardTopEndSync,
                ),
              ),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final item = items[index];

                final isDrawTop = index == 0 ? true : false;
                final isDrawBottom = index == items.length - 1 ? true : false;

                return GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '${item.value}'));
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              S.of(context).trade_details_copied(item.title)),
                          backgroundColor: Colors.green,
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                    },
                    child: StandartListRow(
                      title: '${item.title}',
                      value: '${item.value}',
                      isDrawTop: isDrawTop,
                      isDrawBottom: isDrawBottom,
                    ));
              });
        }));
  }
}
