import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/standart_switch.dart';

class SettingsSwitcherCell extends StandardListRow {
  SettingsSwitcherCell(
      {@required String title, @required this.value, this.onValueChange})
      : super(title: title, isSelected: false);

  final bool value;
  final void Function(BuildContext context, bool value) onValueChange;

  @override
  Widget buildTrailing(BuildContext context) => StandartSwitch(
      value: value, onTaped: () => onValueChange(context, !value));
}
