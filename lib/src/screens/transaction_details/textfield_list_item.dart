import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:flutter/foundation.dart';

class TextFieldListItem extends TransactionDetailsListItem {
  TextFieldListItem({
    required String title,
    required String value,
    required this.onSubmitted,
    Key? key,
  }) : super(
          title: title,
          value: value,
          key: key,
        );

  final Function(String value) onSubmitted;
}