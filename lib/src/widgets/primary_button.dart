import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {@required this.onPressed,
      @required this.text,
      @required this.color,
      @required this.borderColor,
      
      this.isDisabled = false});

  final VoidCallback onPressed;
  final Color color;
  final Color borderColor;
  final String text;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
        minWidth: double.infinity,
        height: 56.0,
        child: FlatButton(
          onPressed: isDisabled ? null : onPressed,
          color: isDisabled ? Colors.grey : color,
          shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(10.0)),
          child: Text(text,
              style: TextStyle(
                  fontSize: 16.0,
                  color: isDisabled ? Palette.darkGrey :  Theme.of(context).primaryTextTheme.button.color)),
        ));
  }
}

class LoadingPrimaryButton extends StatelessWidget {
  const LoadingPrimaryButton(
      {@required this.onPressed,
      @required this.text,
      @required this.color,
      @required this.borderColor,
      this.isDisabled = false,
      this.isLoading = false});

  final VoidCallback onPressed;
  final Color color;
  final Color borderColor;
  final bool isLoading;
  final bool isDisabled;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
        minWidth: double.infinity,
        height: 56.0,
        child: FlatButton(
          onPressed: (isLoading || isDisabled) ? null : onPressed,
          color: color,
          shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(10.0)),
          child: isLoading
              ? CupertinoActivityIndicator(animating: true)
              : Text(text,
                  style: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context).primaryTextTheme.button.color)),
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
      this.color = Palette.purple,
      this.borderColor = Palette.deepPink,
      this.iconColor = Colors.black});

  final VoidCallback onPressed;
  final Image image;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
        minWidth: double.infinity,
        height: 58.0,
        child: FlatButton(
          onPressed: onPressed,
          color: color,
          shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(12.0)),
          child: Row(
            children: <Widget>[
              Container(
                width: 28.0,
                height: 56.0,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.transparent),
                child: image,
              ),
              Expanded(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                    Container(
                      height: 56.0,
                      child: Center(
                        child: Text(text,
                            style: TextStyle(
                                fontSize: 18.0,
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .button
                                    .color)),
                      ),
                    )
                  ]))
            ],
          ),
        ));
  }
}
