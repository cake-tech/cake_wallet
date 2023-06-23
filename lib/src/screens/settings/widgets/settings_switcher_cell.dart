import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/standard_switch.dart';

class SettingsSwitcherCell extends StandardListRow {
  SettingsSwitcherCell({
    required String title,
    required this.value,
    this.onValueChange,
    Decoration? decoration,
    this.leading,
    void Function(BuildContext context)? onTap,
  }) : super(title: title, isSelected: false, decoration: decoration, onTap: onTap);

  final bool value;
  final void Function(BuildContext context, bool value)? onValueChange;
  final Widget? leading;

  @override
  Widget buildTrailing(BuildContext context) =>
      StandardSwitch(value: value, onTaped: () => onValueChange?.call(context, !value));

  @override
  Widget? buildLeading(BuildContext context) => leading;
}
