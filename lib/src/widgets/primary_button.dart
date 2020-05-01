import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {@required this.onPressed,
      @required this.text,
      @required this.color,
      @required this.textColor,
      this.isDisabled = false,
      this.onDisabledPressed});

  final VoidCallback onPressed;
  final VoidCallback onDisabledPressed;
  final Color color;
  final Color textColor;
  final String text;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
        minWidth: double.infinity,
        height: 52.0,
        child: FlatButton(
          onPressed: isDisabled
              ? (onDisabledPressed != null ? onDisabledPressed : null)
              : onPressed,
          color: isDisabled ? color.withOpacity(0.5) : color,
          disabledColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26.0)),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey.withOpacity(0.5)
                      : textColor)),
        ));
  }
}

class LoadingPrimaryButton extends StatelessWidget {
  const LoadingPrimaryButton(
      {@required this.onPressed,
        @required this.text,
        @required this.color,
        @required this.textColor,
        this.isDisabled = false,
        this.isLoading = false});

  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final bool isLoading;
  final bool isDisabled;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
        minWidth: double.infinity,
        height: 52.0,
        child: FlatButton(
          onPressed: (isLoading || isDisabled) ? null : onPressed,
          color: color,
          disabledColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26.0)),
          child: isLoading
              ? CupertinoActivityIndicator(animating: true)
              : Text(text,
              style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.grey.withOpacity(0.5)
                      : textColor
              )),
        ));
  }
}

class PrimaryIconButton extends StatelessWidget {
  const PrimaryIconButton({
    @required this.onPressed,
    @required this.iconData,
    @required this.text,
    @required this.color,
    @required this.borderColor,
    @required this.iconColor,
    @required this.iconBackgroundColor,
  });

  final VoidCallback onPressed;
  final IconData iconData;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
        minWidth: double.infinity,
        height: 56.0,
        child: FlatButton(
          onPressed: onPressed,
          color: color,
          shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(10.0)),
          child: Stack(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 28.0,
                    height: 56.0,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: iconBackgroundColor),
                    child: Icon(iconData, color: iconColor, size: 22.0),
                  ),
                ],
              ),
              Container(
                height: 56.0,
                child: Center(
                  child: Text(text,
                      style: TextStyle(
                          fontSize: 16.0,
                          color:
                              Theme.of(context).primaryTextTheme.button.color)),
                ),
              )
            ],
          ),
        ));
  }
}

class PrimaryImageButton extends StatelessWidget {
  const PrimaryImageButton(
      {@required this.onPressed,
      @required this.image,
      @required this.text,
      @required this.color,
      @required this.textColor});

  final VoidCallback onPressed;
  final Image image;
  final Color color;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
        minWidth: double.infinity,
        height: 52.0,
        child: FlatButton(
          onPressed: onPressed,
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26.0)),
          child:Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                image,
                SizedBox(width: 15),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor
                  ),
                )
              ],
            ),
          )
        ));
  }
}
