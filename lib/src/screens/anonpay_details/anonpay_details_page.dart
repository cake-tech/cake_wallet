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
  Widget body(BuildContext context) => AnonpayDetailsPageBody(anonpayDetailsViewModel);
}

class AnonpayDetailsPageBody extends StatefulWidget {
  AnonpayDetailsPageBody(this.anonpayDetailsViewModel);

  final AnonpayDetailsViewModel anonpayDetailsViewModel;

  @override
  State<AnonpayDetailsPageBody> createState() => _AnonpayDetailsPageBodyState();
}

class _AnonpayDetailsPageBodyState extends State<AnonpayDetailsPageBody> {
  @override
  void dispose() {
    super.dispose();
    widget.anonpayDetailsViewModel.timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SectionStandardList(
        sectionCount: 1,
        itemCounter: (int _) => widget.anonpayDetailsViewModel.items.length,
        itemBuilder: (__, index) {
          final item = widget.anonpayDetailsViewModel.items[index];

          if (item is DetailsListStatusItem) {
            return StandardListStatusRow(title: item.title, value: item.value);
          }

          if (item is TradeDetailsListCardItem) {
            return TradeDetailsStandardListCard(
              id: item.id,
              create: item.createdAt,
              pair: item.pair,
              currentTheme: widget.anonpayDetailsViewModel.settingsStore.currentTheme.type,
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
