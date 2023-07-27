import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';

class BlockExplorerListItem extends TransactionDetailsListItem {
  BlockExplorerListItem({required String title, required String value, required this.onTap})
      : super(title: title, value: value);
  final Function() onTap;
}
