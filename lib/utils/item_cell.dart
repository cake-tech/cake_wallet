import 'package:flutter/foundation.dart';
import 'package:cake_wallet/utils/mobx.dart';

class ItemCell<Item> with Keyable {
  ItemCell(this.value, {@required this.isSelected, @required dynamic key}) {
    keyIndex = key;
  }

  final Item value;
  final bool isSelected;
}
