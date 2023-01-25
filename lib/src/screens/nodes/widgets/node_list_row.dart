import 'package:cake_wallet/src/screens/nodes/widgets/node_indicator.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:flutter/material.dart';

class NodeListRow extends StandardListRow {
  NodeListRow(
      {required String title,
      required void Function(BuildContext context) onTap,
      required bool isSelected,
      required this.isAlive})
      : super(title: title, onTap: onTap, isSelected: isSelected);

  final Future<bool> isAlive;

  @override
  Widget buildTrailing(BuildContext context) {
    return FutureBuilder(
        future: isAlive,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return NodeIndicator(isLive: (snapshot.data as bool?) ?? false);
            default:
              return NodeIndicator(isLive: false);
          }
        });
  }
}

class NodeHeaderListRow extends StandardListRow {
  NodeHeaderListRow({required String title, required void Function(BuildContext context) onTap})
      : super(title: title, onTap: onTap, isSelected: false);

  @override
  Widget buildTrailing(BuildContext context) {
    return SizedBox(
      width: 20,
      child: Icon(Icons.add,
          color: Theme.of(context).accentTextTheme.subtitle1?.color, size: 24.0),
    );
  }
}
