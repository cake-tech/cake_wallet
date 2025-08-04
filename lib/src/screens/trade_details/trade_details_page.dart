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
import 'package:cake_wallet/themes/core/material_base_theme.dart';
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
  Widget body(BuildContext context) => TradeDetailsPageBody(tradeDetailsViewModel, currentTheme);
}

class TradeDetailsPageBody extends StatefulWidget {
  TradeDetailsPageBody(this.tradeDetailsViewModel, this.currentTheme);

  final TradeDetailsViewModel tradeDetailsViewModel;
  final MaterialThemeBase currentTheme;

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
    return Observer(
      builder: (_) {
        final itemsCount = tradeDetailsViewModel.items.length;

        return SectionStandardList(
          sectionCount: 1,
          itemCounter: (int _) => itemsCount,
          itemBuilder: (__, index) {
            final item = tradeDetailsViewModel.items[index];

            if (item is TrackTradeListItem)
              return ListRow(
                title: '${item.title}',
                value: '${item.value}',
                hintTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
                textWidget: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '${item.value}'));
                    showBar<void>(context, S.of(context).copied_to_clipboard);
                  },
                  child: Text(
                    '${item.value}',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                image: GestureDetector(
                  onTap: item.onTap,
                  child: Icon(
                    Icons.launch_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );

            if (item is DetailsListStatusItem)
              return StandardListStatusRow(title: item.title, value: item.value);

            if (item is TradeDetailsListCardItem)
              return TradeDetailsStandardListCard(
                id: item.id,
                extraId: item.extraId,
                create: item.createdAt,
                pair: item.pair,
                currentTheme: widget.currentTheme.type,
                onTap: item.onTap,
              );

            if (item is TradeProviderUnsupportedItem)
              return AutoSizeText(
                item.value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.error,
                    ),
              );

            return GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: '${item.value}'));
                showBar<void>(context, S.of(context).copied_to_clipboard);
              },
              child: ListRow(
                title: '${item.title}',
                value: '${item.value}',
                hintTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        );
      },
    );
  }
}
