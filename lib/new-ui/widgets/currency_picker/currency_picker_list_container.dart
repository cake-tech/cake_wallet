import 'package:flutter/material.dart';

class CurrencyPickerListContainer extends StatelessWidget {
  const CurrencyPickerListContainer({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(_divider(context));
      }
    }
    return Container(
      decoration: _decoration(context),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// A [CurrencyPickerListContainer] whose rows are only built once they scroll into view, for
/// lists as long as the providers' assets
class CurrencyPickerSliverList extends StatelessWidget {
  const CurrencyPickerSliverList({required this.itemCount, required this.itemBuilder, super.key});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => DecoratedSliver(
    decoration: _decoration(context),
    sliver: SliverList.separated(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      separatorBuilder: (context, _) => _divider(context),
    ),
  );
}

BoxDecoration _decoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainer,
  borderRadius: BorderRadius.circular(18),
);

Widget _divider(BuildContext context) => Divider(
  height: 1,
  thickness: 1,
  color: Theme.of(context).colorScheme.surfaceContainerHigh,
  indent: 52,
  endIndent: 12,
);
