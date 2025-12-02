import 'package:flutter/material.dart';

class ListRow extends StatelessWidget {
  ListRow(
      {required this.title,
      required this.value,
      this.titleFontSize = 14,
      this.valueFontSize = 16,
      this.image,
      this.padding,
      this.color,
      this.hintTextColor,
      this.mainTextColor,
      this.textWidget});

  final String title;
  final String value;
  final double titleFontSize;
  final double valueFontSize;
  final Widget? image;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? hintTextColor;
  final Color? mainTextColor;
  final Widget? textWidget;

  Widget _getTextWidget(BuildContext context) =>
      textWidget ??
      Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w500,
              color: mainTextColor,
            ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color ?? Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: padding ?? const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w500,
                  color: hintTextColor,
                ),
            textAlign: TextAlign.left,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _getTextWidget(context)),
                image != null
                    ? Padding(
                        padding: EdgeInsets.only(left: 24),
                        child: image,
                      )
                    : Offstage()
              ],
            ),
          )
        ]),
      ),
    );
  }
}
