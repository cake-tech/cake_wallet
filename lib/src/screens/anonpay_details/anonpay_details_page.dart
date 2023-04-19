import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_list_card.dart';
import 'package:cake_wallet/src/screens/trade_details/trade_details_status_item.dart';
import 'package:cake_wallet/src/widgets/list_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/standard_list_card.dart';
import 'package:cake_wallet/src/widgets/standard_list_status_row.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/anonpay_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnonpayDetailsPage extends BasePage {
  AnonpayDetailsPage({required this.anonpayDetailsViewModel});

  @override
  String get title => S.current.invoice_details;

  final AnonpayDetailsViewModel anonpayDetailsViewModel;

  @override
  Widget body(BuildContext context) {
    return SectionStandardList(
        context: context,
        sectionCount: 1,
        itemCounter: (int _) => anonpayDetailsViewModel.items.length,
        itemBuilder: (_, __, index) {
          final item = anonpayDetailsViewModel.items[index];

          if (item is DetailsListStatusItem) {
            return StandardListStatusRow(title: item.title, value: item.value);
          }

          if (item is TradeDetailsListCardItem) {
            return TradeDetailsStandardListCard(
              id: item.id,
              create: item.createdAt,
              pair: item.pair,
              currentTheme: anonpayDetailsViewModel.settingsStore.currentTheme.type,
              onTap: item.onTap,
            );
          }

            return GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: item.value));
                showBar<void>(context, S.of(context).transaction_details_copied(item.title));
              },
              child: ListRow(title: '${item.title}:', value: item.value),
            );
          

        });
  }
}
