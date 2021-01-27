import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';

class BlockExplorerListItem extends TransactionDetailsListItem {
  BlockExplorerListItem({String title, String value, this.onTap})
      : super(title: title, value: value);
  final Function() onTap;
}
