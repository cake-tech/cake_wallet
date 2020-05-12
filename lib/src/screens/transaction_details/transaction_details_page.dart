import 'package:cake_wallet/src/domain/monero/monero_transaction_info.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_row.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class TransactionDetailsPage extends BasePage {
  TransactionDetailsPage({this.transactionInfo});

  final TransactionInfo transactionInfo;

  @override
  bool get isModalBackButton => true;

  @override
  String get title => S.current.transaction_details_title;

  @override
  Widget body(BuildContext context) {
    final settingsStore = Provider.of<SettingsStore>(context);

    return TransactionDetailsForm(
        transactionInfo: transactionInfo, settingsStore: settingsStore);
  }
}

class TransactionDetailsForm extends StatefulWidget {
  TransactionDetailsForm(
      {@required this.transactionInfo, @required this.settingsStore});

  final TransactionInfo transactionInfo;
  final SettingsStore settingsStore;

  @override
  TransactionDetailsFormState createState() => TransactionDetailsFormState();
}

class TransactionDetailsFormState extends State<TransactionDetailsForm> {
  final _items = List<StandartListItem>();

  @override
  void initState() {
    final _dateFormat = widget.settingsStore.getCurrentDateFormat(
        formatUSA: "yyyy.MM.dd, HH:mm", formatDefault: "dd.MM.yyyy, HH:mm");
    final tx = widget.transactionInfo;

    if (tx is MoneroTransactionInfo) {
      final items = [
        StandartListItem(
            title: S.current.transaction_details_transaction_id, value: tx.id),
        StandartListItem(
            title: S.current.transaction_details_date,
            value: _dateFormat.format(tx.date)),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted())
      ];

      if (widget.settingsStore.shouldSaveRecipientAddress &&
          tx.recipientAddress != null) {
        items.add(StandartListItem(
            title: S.current.transaction_details_recipient_address,
            value: tx.recipientAddress));
      }

      _items.addAll(items);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 15, top: 10, bottom: 10),
      child: ListView.separated(
          separatorBuilder: (context, index) => Container(
                height: 1,
                color: Theme.of(context).dividerTheme.color,
              ),
          padding: EdgeInsets.only(left: 25, top: 10, right: 25, bottom: 15),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];

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
              child:
                  StandartListRow(title: '${item.title}:', value: item.value),
            );
          }),
    );
  }
}
