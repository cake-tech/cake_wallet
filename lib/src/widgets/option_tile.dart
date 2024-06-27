
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  const OptionTile(
      {required this.onPressed,
      required this.image,
      required this.title,
      this.subTitle,
      this.description,
      this.firstBadgeName,
      this.secondBadgeName,
      this.borderRadius,
      this.padding,
      this.titleTextStyle,
      this.leadingIcon,
      this.isSelected = false});

  final VoidCallback onPressed;
  final Image image;
  final String title;
  final String? subTitle;
  final String? description;
  final String? firstBadgeName;
  final String? secondBadgeName;
  final double? borderRadius;
  final EdgeInsets? padding;
  final TextStyle? titleTextStyle;
  final IconData? leadingIcon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? Theme.of(context).extension<OptionTileTheme>()!.titleColor
        : Theme.of(context).cardColor;

    final titleColor = isSelected
        ? Theme.of(context).cardColor
        : Theme.of(context).extension<OptionTileTheme>()!.titleColor;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: padding ?? EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 12)),
          color: backgroundColor,
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                image,
                                SizedBox(width: 8),
                                Text(
                                  title,
                                  style: titleTextStyle ??
                                      TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: titleColor,
                                      ),
                                ),
                                if (firstBadgeName != null)
                                  Badge(
                                    title: firstBadgeName!,
                                    textColor: backgroundColor,
                                    backgroundColor:
                                        titleColor,
                                  ),
                                if (secondBadgeName != null)
                                  Badge(
                                    title: secondBadgeName!,
                                    textColor: backgroundColor,
                                    backgroundColor:
                                        titleColor,
                                  ),
                              ],
                            ),
                            leadingIcon != null
                                ? Icon(Icons.arrow_forward_ios,
                                    size: 16,
                                    color:
                                        titleColor)
                                : Container(),
                          ],
                        ),
                        if (subTitle != null)
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              subTitle!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: titleColor,
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (description != null)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  description!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: titleColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Badge extends StatelessWidget {
  Badge({required this.textColor, required this.backgroundColor, required this.title});

  final String title;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        height: 30,
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.5)), color: backgroundColor),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
