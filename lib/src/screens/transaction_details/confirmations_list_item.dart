import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';

class ConfirmationsListItem extends TransactionDetailsListItem {
  late final int current;
  late final int needed;

  ConfirmationsListItem({required super.title, required super.value, super.key}) {
    final parts = value.split("/");
    current = int.tryParse(parts.first)??0;
    needed = int.tryParse(parts.last)??0;
  }
}