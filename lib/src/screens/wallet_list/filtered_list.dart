import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

class FilteredList extends StatefulWidget {
  FilteredList({
    required this.list,
    required this.itemBuilder,
    required this.updateFunction,
  });

  final ObservableList<WalletListItem> list;
  final Widget Function(BuildContext, int) itemBuilder;
  final Function updateFunction;

  @override
  FilteredListState createState() => FilteredListState();
}

class FilteredListState extends State<FilteredList> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      physics: const BouncingScrollPhysics(),
      itemBuilder: widget.itemBuilder,
      itemCount: widget.list.length,
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final WalletListItem item = widget.list.removeAt(oldIndex);
          widget.list.insert(newIndex, item);
          widget.updateFunction();
        });
      },
    );
  }
}
