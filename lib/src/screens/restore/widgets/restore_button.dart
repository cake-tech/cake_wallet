import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:auto_size_text/auto_size_text.dart';

class RestoreButton extends StatelessWidget {
  const RestoreButton(
      {@required this.onPressed,
      @required this.image,
      @required this.aspectRatioImage,
      @required this.color,
      @required this.titleColor,
      this.title = '',
      this.description = '',
      this.textButton = ''});

  final VoidCallback onPressed;
  final Image image;
  final double aspectRatioImage;
  final Color color;
  final Color titleColor;
  final String title;
  final String description;
  final String textButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.0, bottom: 20.0),
      decoration: BoxDecoration(
          color: Theme.of(context).accentTextTheme.headline.backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          boxShadow: [
            BoxShadow(
              color: Palette.buttonShadow,
              blurRadius: 10,
              offset: Offset(
                0,
                12,
              ),
            )
          ]),
      child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Container(
                  child: AspectRatio(
                    aspectRatio: aspectRatioImage,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: image,
                    ),
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: AutoSizeText(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                    child: AutoSizeText(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).accentTextTheme.subhead.color,
                      ),
                      maxLines: 2,
                    )
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                  height: 56.0,
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Theme.of(context)
                                .accentTextTheme
                                .headline
                                .decorationColor,
                            width: 1.15)),
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      textButton,
                      style: TextStyle(
                          color: color,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ))
            ],
          )),
    );
  }
}
