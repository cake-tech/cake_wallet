import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';

class SideMenuItem extends StatelessWidget {
  const SideMenuItem({
    Key? key,
    required this.onTap,
    this.imagePath,
    this.icon,
    this.widget,
    this.isSelected = false,
  }) : assert(widget != null || icon != null || imagePath != null);

  final void Function() onTap;
  final String? imagePath;
  final IconData? icon;
  final bool isSelected;
  final Widget? widget;

  Color _setColor(BuildContext context) {
    if (isSelected) {
      return Theme.of(context).extension<CakeTextTheme>()!.titleColor;
    } else {
      return Theme.of(context).highlightColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: widget ?? _getIcon(context),
      ),
      onTap: () => onTap.call(),
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
    );
  }

  Widget _getIcon(BuildContext context) {
    return icon != null
        ? Icon(
            icon,
            color: _setColor(context),
          )
        : Image.asset(
            imagePath ?? '',
            fit: BoxFit.cover,
            height: 30,
            width: 30,
            color: _setColor(context),
          );
  }
}
