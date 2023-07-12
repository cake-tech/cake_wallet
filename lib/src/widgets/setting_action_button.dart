import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:flutter/material.dart';

class SettingActionButton extends StatelessWidget {
  final bool isLastTile;
  final bool isSelected;
  final bool isArrowVisible;
  final bool selectionActive;
  final VoidCallback onTap;
  final String image;
  final String title;
  final double fromBottomEdge;
  final double fromTopEdge;
  final double tileHeight;
  const SettingActionButton({
    super.key,
    this.isLastTile = false,
    this.isSelected = false,
    this.selectionActive = true,
    this.isArrowVisible = false,
    required this.onTap,
    required this.image,
    required this.title,
    this.tileHeight = 60,
    this.fromTopEdge = 50,
    this.fromBottomEdge = 25,
  });

  @override
  Widget build(BuildContext context) {
    Color? color = isSelected
        ? Theme.of(context).extension<CakeMenuTheme>()!.settingTitleColor
        : selectionActive
            ? Palette.darkBlue
            : Theme.of(context).extension<CakeMenuTheme>()!.settingTitleColor;
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      child: Container(
        height: tileHeight,
        padding: isLastTile
            ? EdgeInsets.only(
                left: 24,
                right: 24,
                top: fromBottomEdge,
              )
            : EdgeInsets.only(left: 24, right: 24),
        alignment: isLastTile ? Alignment.topLeft : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              image,
              height: 16,
              width: 16,
              color: Theme.of(context)
                  .extension<CakeMenuTheme>()!
                  .settingActionsIconColor,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isArrowVisible)
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              )
          ],
        ),
      ),
    );
  }
}
