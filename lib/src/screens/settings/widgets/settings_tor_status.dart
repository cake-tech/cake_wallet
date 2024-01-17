import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_indicator.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/view_model/settings/tor_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TorStatus extends StandardListRow {
  TorStatus(
      {required String title,
      required bool isSelected,
      required this.torViewModel,
      BoxDecoration? decoration})
      : super(title: title, onTap: null, isSelected: isSelected, decoration: decoration);

  final TorViewModel torViewModel;

  @override
  Widget buildTrailing(BuildContext context) {
    return Observer(builder: (context) {
      Color? color;
      String? text;
      switch (torViewModel.torConnectionStatus) {
        case TorConnectionStatus.connected:
          color = Palette.green;
          text = S.current.connected;
          break;
        case TorConnectionStatus.connecting:
          color = Colors.amber;
          text = S.current.connecting;
          break;
        case TorConnectionStatus.disconnected:
          color = Palette.red;
          text = S.current.disconnected;
          break;
      }
      return NodeIndicator(color: color, text: text);
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
          color: Theme.of(context).extension<FilterTheme>()!.titlesColor, size: 24.0),
    );
  }
}
