import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class PickerItemWidget extends StatelessWidget {
  const PickerItemWidget(
      {this.iconPath, this.title, this.isSelected, this.tag, this.onTap});

  final String iconPath;
  final String title;
  final bool isSelected;
  final String tag;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? Theme.of(context).textTheme.bodyText1.color
            : Theme.of(context).accentTextTheme.headline6.color,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    child: Image.asset(
                      iconPath,
                      height: 32.0,
                      width: 32.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? Palette.blueCraiola
                              : Theme.of(context).primaryTextTheme.title.color,
                          fontSize: 18.0,
                          fontFamily: 'Lato',
                        ),
                      ),
                      tag != null
                          ? Positioned(
                              top: -20.0,
                              right: 7.0,
                              child: Container(
                                width: 35.0,
                                height: 18.0,
                                child: Center(
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                        fontSize: 7.0,
                                        fontFamily: 'Lato',
                                        color: Theme.of(context)
                                            .textTheme
                                            .body1
                                            .color),
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.0),
                                  //border: Border.all(color: ),
                                  color: Theme.of(context)
                                      .textTheme
                                      .body1
                                      .decorationColor,
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ;
  }
}
