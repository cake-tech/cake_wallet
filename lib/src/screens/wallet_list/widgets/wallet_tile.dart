import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class WalletTile extends SliverPersistentHeaderDelegate {
  WalletTile({
    @required this.min,
    @required this.max,
    @required this.image,
    @required this.walletName,
    @required this.walletAddress,
    @required this.isCurrent
  });

  final double min;
  final double max;
  final Image image;
  final String walletName;
  final String walletAddress;
  final bool isCurrent;
  final double tileHeight = 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    var opacity = 1 - shrinkOffset / (max - min);
    opacity = opacity >= 0 ? opacity : 0;

    var panelWidth = 10 * opacity;
    panelWidth = panelWidth < 10 ? 0 : 10;

    final currentColor = isCurrent
        ? Theme.of(context).accentTextTheme.subtitle.decorationColor
        : Theme.of(context).backgroundColor;

    return Stack(
      fit: StackFit.expand,
      overflow: Overflow.visible,
      children: <Widget>[
        Positioned(
          top: 0,
          right: max - 4,
          child: Container(
            height: tileHeight,
            width: 4,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                color: currentColor
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 10,
          child: Container(
            height: tileHeight,
            width: max - 14,
            padding: EdgeInsets.only(left: 20, right: 20),
            color: Theme.of(context).backgroundColor,
            alignment: Alignment.centerLeft,
            child: Row(
              //mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                image,
                SizedBox(width: 10),
                Text(
                  walletName,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryTextTheme.title.color
                  ),
                )
              ],
            ),
            /*Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    image,
                    SizedBox(width: 10),
                    Text(
                      walletName,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryTextTheme.title.color
                      ),
                    )
                  ],
                ),
                isCurrent ? SizedBox(height: 5) : Offstage(),
                isCurrent
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(width: 34),
                    Text(
                      walletAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryTextTheme.caption.color
                      ),
                    )
                  ],
                )
                : Offstage()
              ],
            ),*/
          ),
        ),
        Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: opacity,
              child: Container(
                height: tileHeight,
                width: panelWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                  gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).accentTextTheme.headline.color,
                          Theme.of(context).accentTextTheme.headline.backgroundColor
                        ]
                  )
                ),
              ),
            )
        ),
      ],
    );
  }

  @override
  double get maxExtent => max;

  @override
  double get minExtent => min;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;

}