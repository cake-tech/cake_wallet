import 'package:flutter/material.dart';

class SelectButton extends StatelessWidget {
  SelectButton({
    @required this.image,
    @required this.text,
    @required this.color,
    @required this.textColor,
    @required this.onTap,
  });

  final Image image;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  final selectArrowImage = Image.asset('assets/images/select_arrow.png');

  @override
  Widget build(BuildContext context) {
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
                image != null
                    ? image
                    : Offstage(),
                Padding(
                  padding: image != null
                      ? EdgeInsets.only(left: 15)
                      : EdgeInsets.only(left: 0),
                  child: Text(
                    text,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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