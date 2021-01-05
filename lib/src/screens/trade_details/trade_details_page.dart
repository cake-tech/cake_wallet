import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/trade_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';

class TradeDetailsPage extends BasePage {
  TradeDetailsPage(this.tradeDetailsViewModel);

  @override
  String get title => S.current.trade_details_title;

  final TradeDetailsViewModel tradeDetailsViewModel;

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
          itemCount: tradeDetailsViewModel.items.length,
          itemBuilder: (BuildContext context, int index) {
            final item = tradeDetailsViewModel.items[index];
            final isDrawBottom =
              index == tradeDetailsViewModel.items.length - 1 ? true : false;

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
