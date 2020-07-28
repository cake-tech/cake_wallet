import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class CakeScrollbar extends StatelessWidget {
  CakeScrollbar({
    @required this.backgroundHeight,
    @required this.thumbHeight,
    @required this.fromTop
  });

  final double backgroundHeight;
  final double thumbHeight;
  final double fromTop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        right: 6,
        child: Container(
          height: backgroundHeight,
          width: 6,
          decoration: BoxDecoration(
            color: PaletteDark.violetBlue,
            borderRadius: BorderRadius.all(Radius.circular(3))
          ),
          child: Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: Duration(milliseconds: 0),
                top: fromTop,
                child: Container(
                  height: thumbHeight,
                  width: 6.0,
                  decoration: BoxDecoration(
                    color: PaletteDark.wildBlueGrey,
                    borderRadius: BorderRadius.all(Radius.circular(3))
                  ),
                ),
              )
            ],
          ),
        )
    );
  }
}