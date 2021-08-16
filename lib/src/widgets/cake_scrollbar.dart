import 'package:flutter/material.dart';

class CakeScrollbar extends StatelessWidget {
  CakeScrollbar({
    @required this.backgroundHeight,
    @required this.thumbHeight,
    @required this.fromTop,
    this.rightOffset = 6
  });

  final double backgroundHeight;
  final double thumbHeight;
  final double fromTop;
  final double rightOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        right: rightOffset,
        child: Container(
          height: backgroundHeight,
          width: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).textTheme.body1.decorationColor,
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
                    color: Theme.of(context).textTheme.body1.color,
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