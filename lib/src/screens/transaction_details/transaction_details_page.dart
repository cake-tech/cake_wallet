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
import 'package:cake_wallet/palette.dart';

class TransactionDetailsPage extends BasePage {
  TransactionDetailsPage({this.transactionInfo});

  final TransactionInfo transactionInfo;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

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
          formatUSA: "yyyy.MM.dd, HH:mm",
          formatDefault: "dd.MM.yyyy, HH:mm");
    final items = [
      StandartListItem(
          title: S.current.transaction_details_transaction_id,
          value: widget.transactionInfo.id),
      StandartListItem(
          title: S.current.transaction_details_date,
          value: _dateFormat.format(widget.transactionInfo.date)),
      StandartListItem(
          title: S.current.transaction_details_height,
          value: '${widget.transactionInfo.height}'),
      StandartListItem(
          title: S.current.transaction_details_amount,
          value: widget.transactionInfo.amountFormatted())
    ];

    if (widget.settingsStore.shouldSaveRecipientAddress &&
        widget.transactionInfo.recipientAddress != null) {
      items.add(StandartListItem(
          title: S.current.transaction_details_recipient_address,
          value: widget.transactionInfo.recipientAddress));
    }

    _items.addAll(items);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PaletteDark.historyPanel,
      padding: EdgeInsets.only(top: 20, bottom: 20),
      child: ListView.separated(
          separatorBuilder: (context, index) => Container(
            height: 1,
            padding: EdgeInsets.only(left: 24),
            color: PaletteDark.menuList,
            child: Container(
              height: 1,
              color: PaletteDark.walletCardTopEndSync,
            ),
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];

            final isDrawTop = index == 0 ? true : false;
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
              child:
              StandartListRow(
                  title: '${item.title}:',
                  value: item.value,
                  isDrawTop: isDrawTop,
                  isDrawBottom: isDrawBottom),
            );
          }),
    );
  }
}
