import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';

class UnspentCoinsSwitchItem extends TransactionDetailsListItem {
  UnspentCoinsSwitchItem({
    String title,
    String value,
    this.switchValue,
    this.onSwitchValueChange}) : super(title: title, value: value);

  final bool Function() switchValue;
  final void Function(bool value) onSwitchValueChange;
}