import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  const OptionTile(
      {required this.onPressed,
      required this.image,
      required this.title,
      required this.description,
      this.borderRadius,
      this.padding,
      this.titleTextStyle,
      this.leadingIcon});

  final VoidCallback onPressed;
  final Image image;
  final String title;
  final String description;
  final double? borderRadius;
  final EdgeInsets? padding;
  final TextStyle? titleTextStyle;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: padding ?? EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 12)),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
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
                                    color:
                                        Theme.of(context).extension<OptionTileTheme>()!.titleColor,
                                  ),
                            )
                          ],
                        ),
                        leadingIcon != null
                            ? Icon(Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).extension<OptionTileTheme>()!.titleColor)
                            : Container(),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).extension<OptionTileTheme>()!.titleColor,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
