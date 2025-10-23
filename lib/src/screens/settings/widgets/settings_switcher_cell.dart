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
    this.padding,
    this.switchBackgroundColor,
  }) : super(title: title, isSelected: false, decoration: decoration, onTap: onTap, key: key);

  final bool value;
  final Color? switchBackgroundColor;
  final void Function(BuildContext context, bool value)? onValueChange;
  final Widget? leading;
  final EdgeInsets? padding;

  @override
  Widget buildTrailing(BuildContext context) => StandardSwitch(
        value: value,
        onTapped: () => onValueChange?.call(context, !value),
        backgroundColor: switchBackgroundColor,
      );

  @override
  Widget build(BuildContext context) {
    final leading = buildLeading(context);
    final trailing = buildTrailing(context);
    return Container(
      height: 56,
      padding: padding ?? EdgeInsets.only(left: 12, right: 12),
      child: TextButton(
        onPressed: () {
          if (onTap != null) {
            onTap!.call(context);
          } else {
            onValueChange?.call(context, !value);
          }
        },
        style: ButtonStyle(
          padding: WidgetStateProperty.all(padding ?? null),
          //backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.surfaceContainer),
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
  Widget? buildLeading(BuildContext context) => leading;
}
