import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

class FilteredWalletList extends StatefulWidget {
  FilteredWalletList({required this.walletList, required this.itemBuilder});

  final ObservableList<WalletListItem> walletList;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  FilteredWalletListState createState() => FilteredWalletListState();
}

class FilteredWalletListState extends State<FilteredWalletList> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      physics: const BouncingScrollPhysics(),
      itemBuilder: widget.itemBuilder,
      itemCount: widget.walletList.length,
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final WalletListItem item = widget.walletList.removeAt(oldIndex);
          widget.walletList.insert(newIndex, item);
        });
      },
    );
  }
}
