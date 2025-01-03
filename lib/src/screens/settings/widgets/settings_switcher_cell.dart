import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:flutter/material.dart';

class SettingsSwitcherCell extends StandardListRow {
  SettingsSwitcherCell({
    required String title,
    required this.value,
    this.onValueChange,
    Decoration? decoration,
    this.leading,
    void Function(BuildContext context)? onTap,
    Key? key,
  }) : super(title: title, isSelected: false, decoration: decoration, onTap: onTap, key: key);

  final bool value;
  final void Function(BuildContext context, bool value)? onValueChange;
  final Widget? leading;

  @override
  Widget buildTrailing(BuildContext context) =>
      StandardSwitch(value: value, onTaped: () => onValueChange?.call(context, !value));

  @override
  Widget build(BuildContext context) {
    final leading = buildLeading(context);
    final trailing = buildTrailing(context);
    return Container(
      height: 56,
      padding: EdgeInsets.only(left: 12, right: 12),
      child: TextButton(
        onPressed: () => onValueChange?.call(context, !value),
        style: ButtonStyle(
          //backgroundColor: MaterialStateProperty.all(Theme.of(context).cardColor),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)
              ),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            if (leading != null) leading,
            buildCenter(context, hasLeftOffset: leading != null),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }


  @override
  Widget? buildLeading(BuildContext context) => leading;
}
