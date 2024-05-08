import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';

class StandardExpandableListItem<T> extends TransactionDetailsListItem {
  StandardExpandableListItem({required String title, required this.expandableItems})
      : super(title: title, value: '');
  final List<T> expandableItems;
}
