import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/src/domain/monero/monero_transaction_info.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class TransactionDetailsPage extends BasePage {
  TransactionDetailsPage({this.transactionInfo}) : _items = [] {
    // FIXME
//    final _dateFormat = widget.settingsStore.getCurrentDateFormat(
//        formatUSA: "yyyy.MM.dd, HH:mm", formatDefault: "dd.MM.yyyy, HH:mm");
    final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');
    final tx = transactionInfo;

    if (tx is MoneroTransactionInfo) {
      final items = [
        StandartListItem(
            title: S.current.transaction_details_transaction_id, value: tx.id),
        StandartListItem(
            title: S.current.transaction_details_date,
            value: dateFormat.format(tx.date)),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted())
      ];
      // FIXME
//      if (widget.settingsStore.shouldSaveRecipientAddress &&
//          tx.recipientAddress != null) {
//        items.add(StandartListItem(
//            title: S.current.transaction_details_recipient_address,
//            value: tx.recipientAddress));
//      }

      _items.addAll(items);
    }

    if (tx is BitcoinTransactionInfo) {
      final items = [
        StandartListItem(
            title: S.current.transaction_details_transaction_id, value: tx.id),
        StandartListItem(
            title: S.current.transaction_details_date,
            value: dateFormat.format(tx.date)),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted())
      ];

      _items.addAll(items);
    }
  }

  @override
  String get title => S.current.transaction_details_title;

  final TransactionInfo transactionInfo;

  final List<StandartListItem> _items;

  @override
  Widget body(BuildContext context) {
    return Container(
      child: ListView.separated(
          separatorBuilder: (context, index) => Container(
                height: 1,
                padding: EdgeInsets.only(left: 24),
                color: Theme.of(context).backgroundColor,
                child: Container(
                  height: 1,
                  color: Theme.of(context).primaryTextTheme.title.backgroundColor,
                ),
              ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final isDrawBottom = index == _items.length - 1 ? true : false;

            return GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: item.value));
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        S.of(context).transaction_details_copied(item.title)),
                    backgroundColor: Colors.green,
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              },
              child: StandartListRow(
                  title: '${item.title}:',
                  value: item.value,
                  isDrawBottom: isDrawBottom),
            );
          }),
    );
  }
}
