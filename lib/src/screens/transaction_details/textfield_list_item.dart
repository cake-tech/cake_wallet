import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';

class TextFieldListItem extends TransactionDetailsListItem {
  TextFieldListItem({
    required String title,
    required String value,
    required this.onSubmitted})
      : super(title: title, value: value);

  final Function(String value) onSubmitted;
}