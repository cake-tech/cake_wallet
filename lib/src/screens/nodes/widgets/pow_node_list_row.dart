import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_indicator.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cw_core/pow_node.dart';
import 'package:flutter/material.dart';

class PowNodeListRow extends StandardListRow {
  PowNodeListRow(
      {required String title,
      required this.node,
      required void Function(BuildContext context) onTap,
      required bool isSelected})
      : super(title: title, onTap: onTap, isSelected: isSelected);

  final PowNode node;

  @override
  Widget buildLeading(BuildContext context) {
    return FutureBuilder(
        future: node.requestNode(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return NodeIndicator(isLive: (snapshot.data as bool?) ?? false);
            default:
              return NodeIndicator(isLive: false);
          }
        });
  }

  @override
  Widget buildTrailing(BuildContext context) {
    return GestureDetector(
        onTap: () => Navigator.of(context)
            .pushNamed(Routes.newNode, arguments: {'editingNode': node, 'isSelected': isSelected}),
        child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).extension<ReceivePageTheme>()!.iconsBackgroundColor),
            child: Icon(Icons.edit,
                size: 14, color: Theme.of(context).extension<ReceivePageTheme>()!.iconsColor)));
  }
}

class PowNodeHeaderListRow extends StandardListRow {
  PowNodeHeaderListRow({required String title, required void Function(BuildContext context) onTap})
      : super(title: title, onTap: onTap, isSelected: false);

  @override
  Widget buildTrailing(BuildContext context) {
    return SizedBox(
      width: 20,
      child:
          Icon(Icons.add, color: Theme.of(context).accentTextTheme!.titleMedium!.color, size: 24.0),
    );
  }
}
