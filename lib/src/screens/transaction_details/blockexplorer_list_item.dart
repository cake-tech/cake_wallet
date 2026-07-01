import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:flutter/foundation.dart';

class BlockExplorerListItem extends TransactionDetailsListItem {
  BlockExplorerListItem({
    required String title,
    required String value,
    required this.onTap,
    Key? key,
  }) : super(title: title, value: value, key: key);
  final Function() onTap;
}
