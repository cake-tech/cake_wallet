import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/keyable.dart';
// part 'node_list_view_model.g.dart';
//
// class NodeListViewModel = NodeListViewModelBase with _$NodeListViewModel;

class ItemCell<Item> with Keyable {
  ItemCell(this.value, {
    required this.isSelectedBuilder,
    required dynamic key}) {
    keyIndex = key;
  }

  final Item value;

  bool get isSelected => isSelectedBuilder(value);
  bool Function(Item item) isSelectedBuilder;
}
