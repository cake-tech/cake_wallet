import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';

class TextFieldListItem extends TransactionDetailsListItem {
  TextFieldListItem({String title, String value, this.onSubmitted})
      : super(title: title, value: value);

  final Function(String value) onSubmitted;
}