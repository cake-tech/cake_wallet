import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/widgets/textfield_list_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/utils/date_formatter.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:hive/hive.dart';

String stripURLToTXID(String inputString) {
  final RegExp txidRegex = new RegExp('[a-z0-9]{64}');
  return txidRegex.allMatches(inputString).first.group(0);
}

String blockExplorerName(String inputName) {
  if (inputName.contains("xmrchain")) {
    return "XMRChain.net";
  } else {
    return "Blockchain.com";
  }
}

class TransactionDetailsPage extends BasePage {
  TransactionDetailsPage({this.transactionDetailsViewModel});

  @override
  String get title => S.current.transaction_details_title;

  final TransactionDetailsViewModel transactionDetailsViewModel;

  @override
  Widget body(BuildContext context) {
    return SectionStandardList(
        sectionCount: 1,
        itemCounter: (int _) => transactionDetailsViewModel.items.length,
        itemBuilder: (_, __, index) {
          final item = transactionDetailsViewModel.items[index];

          if (item is StandartListItem) {
            final isFinalBlockExplorerItem =
                index == transactionDetailsViewModel.items.length - 1
                    ? true
                    : false;
            if (isFinalBlockExplorerItem == false) {
              return GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item.value));
                  showBar<void>(context,
                      S.of(context).transaction_details_copied(item.title));
                },
                child:
                    StandartListRow(title: '${item.title}:', value: item.value),
              );
            } else {
              return GestureDetector(
                onTap: () {
                  launch(item.value);
                },
                child: StandartListRow(
                    title: '${item.title}:',
                    value:
                        "View transaction on ${blockExplorerName(item.value)}"),
              );
            }
          }

          if (item is TextFieldListItem) {
            return TextFieldListRow(
              title: item.title,
              value: item.value,
              onSubmitted: item.onSubmitted,
            );
          }

          return null;
        });
  }
}
