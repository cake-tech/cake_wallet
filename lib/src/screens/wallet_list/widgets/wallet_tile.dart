import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/palette.dart';

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

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {

    double opacity = 1 - shrinkOffset / (max - min);
    opacity = opacity >= 0 ? opacity : 0;

    double panelWidth = 12 * opacity;
    panelWidth = panelWidth < 12 ? 0 : 12;

    final currentColor = isCurrent
        ? Colors.white
        : PaletteDark.historyPanel;

    return Stack(
      fit: StackFit.expand,
      overflow: Overflow.visible,
      children: <Widget>[
        Positioned(
          top: 0,
          right: max - 4,
          child: Container(
            height: 108,
            width: 4,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                color: currentColor
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 12,
          child: Container(
            height: 108,
            width: max - 16,
            padding: EdgeInsets.only(left: 20, right: 20),
            color: PaletteDark.historyPanel,
            child: Column(
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
                          color: Colors.white
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
                        color: PaletteDark.walletCardText
                      ),
                    )
                  ],
                )
                : Offstage()
              ],
            ),
          ),
        ),
        Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: opacity,
              child: Container(
                height: 108,
                width: panelWidth,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          PaletteDark.walletCardTopEndSync,
                          PaletteDark.walletCardBottomEndSync
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