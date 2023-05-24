import 'package:flutter/material.dart';

class SelectButton extends StatelessWidget {
  SelectButton({
    required this.text,
    required this.onTap,
    this.image,
    this.isSelected = false,
  });

  final Image? image;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Colors.green
        : Theme.of(context)
            .accentTextTheme!
            .bodySmall!
            .color!;
    final textColor = isSelected
        ? Theme.of(context)
            .accentTextTheme!
            .headlineSmall!
            .decorationColor!
        : Theme.of(context).primaryTextTheme!.titleLarge!.color!;
    final arrowColor = isSelected
        ? Theme.of(context)
            .accentTextTheme!
            .headlineSmall!
            .decorationColor!
        : Theme.of(context)
            .accentTextTheme!
            .titleMedium!
            .color!;

    final selectArrowImage = Image.asset('assets/images/select_arrow.png',
          color: arrowColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        padding: EdgeInsets.only(left: 30, right: 30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          color: color
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                image ?? Offstage(),
                Padding(
                  padding: image != null
                    ? EdgeInsets.only(left: 15)
                    : EdgeInsets.only(left: 0),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: textColor
                    ),
                  ),
                )
              ],
            ),
            selectArrowImage
          ],
        ),
      ),
    );
  }
}