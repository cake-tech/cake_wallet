import 'package:flutter/foundation.dart';

class AccountListItem {
  AccountListItem(
      {@required this.label, @required this.id, this.isSelected = false});

  final String label;
  final int id;
  final bool isSelected;
}
