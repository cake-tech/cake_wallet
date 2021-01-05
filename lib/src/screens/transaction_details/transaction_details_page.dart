import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/widgets/textfield_list_row.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class TransactionDetailsPage extends BasePage {
  TransactionDetailsPage({this.transactionDetailsViewModel});

  @override
  String get title => S.current.transaction_details_title;

  final TransactionDetailsViewModel transactionDetailsViewModel;

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
                  color:
                      Theme.of(context).primaryTextTheme.title.backgroundColor,
                ),
              ),
          itemCount: transactionDetailsViewModel.items.length,
          itemBuilder: (context, index) {
            final item = transactionDetailsViewModel.items[index];
            final isDrawBottom =
              index == transactionDetailsViewModel.items.length - 1
                  ? true : false;

            if (item is StandartListItem) {
              return GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item.value));
                  showBar<void>(context,
                      S.of(context).transaction_details_copied(item.title));
                },
                child: StandartListRow(
                    title: '${item.title}:',
                    value: item.value,
                    isDrawBottom: isDrawBottom),
              );
            }

            if (item is TextFieldListItem) {
              return TextFieldListRow(
                title: item.title,
                value: item.value,
                onSubmitted: item.onSubmitted,
                isDrawBottom: isDrawBottom,
              );
            }

            return null;
          }),
    );
  }
}
