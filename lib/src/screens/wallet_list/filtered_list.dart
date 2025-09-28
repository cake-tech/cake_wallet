import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class FilteredList extends StatefulWidget {
  FilteredList({
    required this.list,
    required this.itemBuilder,
    required this.updateFunction,
    this.canReorder = true,
    this.shrinkWrap = false,
    this.physics,
    this.itemPadding = const EdgeInsets.symmetric(vertical: 4),
  });

  final ObservableList<dynamic> list;
  final Widget Function(BuildContext, int) itemBuilder;
  final Function updateFunction;
  final bool canReorder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsets itemPadding;

  @override
  FilteredListState createState() => FilteredListState();
}

class FilteredListState extends State<FilteredList> {
  Widget _buildPaddedItem(BuildContext ctx, int index) {
    return Padding(
      key: ValueKey(widget.list[index]),
      padding: widget.itemPadding,
      child: widget.itemBuilder(ctx, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canReorder) {
      return Observer(
        builder: (_) => ListView.builder(
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics ?? const BouncingScrollPhysics(),
          itemCount: widget.list.length,
          itemBuilder: _buildPaddedItem,
        ),
      );
    }

    return Observer(
      builder: (_) => ReorderableListView.builder(
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics ?? const BouncingScrollPhysics(),
        itemCount: widget.list.length,
        itemBuilder: _buildPaddedItem,
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) newIndex -= 1;
          final item = widget.list.removeAt(oldIndex);
          widget.list.insert(newIndex, item);
          widget.updateFunction();
        },
        proxyDecorator: (child, _, __) => Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}
