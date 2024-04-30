import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/trade_details/track_trade_list_item.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_list_card.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_provider_unsupported_item.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/standard_list_card.dart';
import 'package:cake_wallet/src/widgets/standard_list_status_row.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/trade_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TradeDetailsPage extends BasePage {
  TradeDetailsPage(this.tradeDetailsViewModel);

  @override
  String get title => S.current.trade_details_title;

  final TradeDetailsViewModel tradeDetailsViewModel;

  @override
  Widget body(BuildContext context) => TradeDetailsPageBody(tradeDetailsViewModel);
}

class TradeDetailsPageBody extends StatefulWidget {
  TradeDetailsPageBody(this.tradeDetailsViewModel);

  final TradeDetailsViewModel tradeDetailsViewModel;

  @override
  TradeDetailsPageBodyState createState() => TradeDetailsPageBodyState(tradeDetailsViewModel);
}

class TradeDetailsPageBodyState extends State<TradeDetailsPageBody> {
  TradeDetailsPageBodyState(this.tradeDetailsViewModel);

  final TradeDetailsViewModel tradeDetailsViewModel;

  @override
  void dispose() {
    super.dispose();
    tradeDetailsViewModel.timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final itemsCount = tradeDetailsViewModel.items.length;

      return SectionStandardList(
          sectionCount: 1,
          itemCounter: (int _) => itemsCount,
          itemBuilder: (__, index) {
            final item = tradeDetailsViewModel.items[index];

            if (item is TrackTradeListItem)
              return GestureDetector(
                  onTap: item.onTap,
                  child: ListRow(title: '${item.title}', value: '${item.value}'));

            if (item is DetailsListStatusItem)
              return StandardListStatusRow(title: item.title, value: item.value);

            if (item is TradeDetailsListCardItem)
              return TradeDetailsStandardListCard(
                id: item.id,
                create: item.createdAt,
                pair: item.pair,
                currentTheme: tradeDetailsViewModel.settingsStore.currentTheme.type,
                onTap: item.onTap,
              );

            if (item is TradeProviderUnsupportedItem)
              return AutoSizeText(item.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ));

            return GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '${item.value}'));
                  showBar<void>(context, S.of(context).copied_to_clipboard);
                },
                child: ListRow(title: '${item.title}', value: '${item.value}'));
          });
    });
  }
}
