import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:flutter/foundation.dart';

class StandardExpandableListItem<T> extends TransactionDetailsListItem {
  StandardExpandableListItem({
    required String title,
    required this.expandableItems,
    Key? key,
  }) : super(title: title, value: '', key: key);
  
  final List<T> expandableItems;
}
