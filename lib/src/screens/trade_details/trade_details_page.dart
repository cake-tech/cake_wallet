import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/trade_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';

class TradeDetailsPage extends BasePage {
  TradeDetailsPage(this.tradeDetailsViewModel);

  @override
  String get title => S.current.trade_details_title;

  final TradeDetailsViewModel tradeDetailsViewModel;

  @override
  Widget body(BuildContext context) {
    return Observer(builder: (_) {
      return SectionStandardList(
          sectionCount: 1,
          itemCounter: (int _) => tradeDetailsViewModel.items.length,
          itemBuilder: (_, __, index) {
            final item = tradeDetailsViewModel.items[index];

            if (item is TrackTradeListItem) {
              return GestureDetector(
                  onTap: item.onTap,
                  child: StandartListRow(
                      title: '${item.title}', value: '${item.value}'));
            } else {
              return GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '${item.value}'));
                    showBar<void>(context, S.of(context).copied_to_clipboard);
                  },
                  child: StandartListRow(
                      title: '${item.title}', value: '${item.value}'));
            }
          });
    });
  }
}
