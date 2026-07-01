import 'package:flutter/foundation.dart';

abstract class TransactionDetailsListItem {
  TransactionDetailsListItem({required this.title, required this.value, this.key});

  final String title;
  final String value;
  final Key? key;
}
