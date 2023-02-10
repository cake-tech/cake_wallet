import 'package:flutter/material.dart';

class SideMenuItem extends StatelessWidget {
  const SideMenuItem({
    Key? key,
    required this.onTap,
    required this.iconPath,
    required this.isSelected,
  }) : super(key: key);

  final void Function() onTap;
  final String iconPath;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    Color _setColor() {
      if (isSelected) {
        return Theme.of(context).primaryTextTheme.headline6!.color!;
      } else {
        return Theme.of(context).highlightColor;
      }
    }

    return InkWell(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Image.asset(
          iconPath,
          fit: BoxFit.cover,
          height: 30,
          width: 30,
          color: _setColor(),
        ),
      ),
      onTap: () => onTap.call(),
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
    );
  }
}
