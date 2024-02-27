import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class FilteredList extends StatefulWidget {
  FilteredList({
    required this.list,
    required this.itemBuilder,
    required this.updateFunction,
  });

  final ObservableList<dynamic> list;
  final Widget Function(BuildContext, int) itemBuilder;
  final Function updateFunction;

  @override
  FilteredListState createState() => FilteredListState();
}

class FilteredListState extends State<FilteredList> {
  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => ReorderableListView.builder(
        physics: const BouncingScrollPhysics(),
        itemBuilder: widget.itemBuilder,
        itemCount: widget.list.length,
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final dynamic item = widget.list.removeAt(oldIndex);
          widget.list.insert(newIndex, item);
          widget.updateFunction();
        },
      ),
    );
  }
}
