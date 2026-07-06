import 'package:flutter/material.dart';

class CurrencyPickerListContainer extends StatelessWidget {
  const CurrencyPickerListContainer({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(Divider(
          height: 1,
          thickness: 1,
          color: colors.surfaceContainerHigh,
          indent: 56,
          endIndent: 24,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
