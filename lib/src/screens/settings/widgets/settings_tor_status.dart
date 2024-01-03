import 'package:cake_wallet/src/screens/nodes/widgets/node_indicator.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:tor/tor.dart';

class TorStatus extends StandardListRow {
  TorStatus(
      {required String title,
      required void Function(BuildContext context) onTap,
      required bool isSelected,
      required this.connected,
      BoxDecoration? decoration})
      : super(title: title, onTap: onTap, isSelected: isSelected, decoration: decoration);

  final bool connected;

  @override
  Widget buildTrailing(BuildContext context) {
    return NodeIndicator(
      isLive: connected,
      showText: true,
    );
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
          color: Theme.of(context).extension<FilterTheme>()!.titlesColor, size: 24.0),
    );
  }
}
