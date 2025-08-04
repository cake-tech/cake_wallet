import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_indicator.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cw_core/node.dart';
import 'package:flutter/material.dart';

class NodeListRow extends StandardListRow {
  NodeListRow(
      {required String title,
      required this.node,
      required void Function(BuildContext context) onTap,
      required bool isSelected,
      required this.isPow})
      : super(title: title, onTap: onTap, isSelected: isSelected);

  final Node node;
  final bool isPow;

  @override
  Widget build(BuildContext context) {
    final leading = buildLeading(context);
    final trailing = buildTrailing(context);
    return Container(
      height: 56,
      padding: EdgeInsets.only(left: 12, right: 12, top: 2, bottom: 2),
      margin: EdgeInsets.only(top: 2, bottom: 2),
      child: FilledButton(
        onPressed: () => onTap?.call(context),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            leading,
            buildCenter(context, hasLeftOffset: true),
            trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return FutureBuilder(
        future: node.requestNode(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return NodeIndicator(isLive: snapshot.data ?? false);
            default:
              return NodeIndicator(isLive: false);
          }
        });
  }

  @override
  Widget buildTrailing(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        isPow ? Routes.newPowNode : Routes.newNode,
        arguments: {'editingNode': node, 'isSelected': isSelected},
      ),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Icon(
          Icons.edit,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class NodeHeaderListRow extends StandardListRow {
  NodeHeaderListRow({required String title, required void Function(BuildContext context) onTap})
      : super(title: title, onTap: onTap, isSelected: false);

  @override
  Widget build(BuildContext context) {
    final leading = buildLeading(context);
    final trailing = buildTrailing(context);
    return Container(
      height: 56,
      padding: EdgeInsets.only(left: 12, right: 12, top: 2, bottom: 2),
      child: TextButton(
        onPressed: () => onTap?.call(context),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            if (leading != null) leading,
            buildCenter(context, hasLeftOffset: leading != null),
            trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget buildTrailing(BuildContext context) {
    return SizedBox(
      width: 20,
      child: Icon(Icons.add,
          color: Theme.of(context).colorScheme.onSurfaceVariant, size: 24.0),
    );
  }
}
