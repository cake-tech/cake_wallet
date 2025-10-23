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
  });

  final ObservableList<dynamic> list;
  final Widget Function(BuildContext, int) itemBuilder;
  final Function updateFunction;
  final bool canReorder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  FilteredListState createState() => FilteredListState();
}

class FilteredListState extends State<FilteredList> {
  @override
  Widget build(BuildContext context) {
    if (widget.canReorder) {
      return Observer(
        builder: (_) => ReorderableListView.builder(
          proxyDecorator: (child, index, animation) => Material(
            child: Container(
              //margin: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 6),
                      spreadRadius: 1)
                ],
              ),
              child: child,
            ),
          ),
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics ?? const BouncingScrollPhysics(),
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
    } else {
      return Observer(
        builder: (_) => ListView.builder(
          physics: widget.physics ?? const BouncingScrollPhysics(),
          itemBuilder: widget.itemBuilder,
          itemCount: widget.list.length,
        ),
      );
    }
  }
}
