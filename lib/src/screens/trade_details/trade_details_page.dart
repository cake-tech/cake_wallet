import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';

class TradeDetailsPage extends BasePage {
  TradeDetailsPage(this.trade) : _items = [] {
    final dateFormat = DateFormatter.withCurrentLocal();
    _items.addAll([
      StandartListItem(title: S.current.trade_details_id, value: trade.id),
      StandartListItem(
          title: S.current.trade_details_state,
          value: trade.state != null
              ? trade.state.toString()
              : S.current.trade_details_fetching)
    ]);

    if (trade.provider != null) {
      _items.add(StandartListItem(
          title: S.current.trade_details_provider,
          value: trade.provider.toString()));
    }

    if (trade.createdAt != null) {
      _items.add(StandartListItem(
          title: S.current.trade_details_created_at,
          value: dateFormat.format(trade.createdAt).toString()));
    }

    if (trade.from != null && trade.to != null) {
      _items.add(StandartListItem(
          title: S.current.trade_details_pair,
          value: '${trade.from.toString()} → ${trade.to.toString()}'));
    }
  }

  @override
  String get title => S.current.trade_details_title;

  final Trade trade;
  final List<StandartListItem> _items;

  @override
  Widget body(BuildContext context) {
    return Container(child: Observer(builder: (_) {
      return ListView.separated(
          separatorBuilder: (_, __) => Container(
              height: 1,
              padding: EdgeInsets.only(left: 24),
              color: Theme.of(context).backgroundColor,
              child: Container(
                  height: 1,
                  color: Theme.of(context)
                      .primaryTextTheme
                      .title
                      .backgroundColor)),
          itemCount: _items.length,
          itemBuilder: (BuildContext context, int index) {
            final item = _items[index];
            final isDrawBottom = index == _items.length - 1 ? true : false;

            return GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '${item.value}'));
                  showBar<void>(context, S.of(context).copied_to_clipboard);
                },
                child: StandartListRow(
                  title: '${item.title}',
                  value: '${item.value}',
                  isDrawBottom: isDrawBottom,
                ));
          });
    }));
  }
}
