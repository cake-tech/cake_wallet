import 'dart:ui';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/screens/dashboard/wallet_menu.dart';

class MenuWidget extends StatefulWidget {
  MenuWidget({this.type, this.name, this.subname});

  final WalletType type;
  final String name;
  final String subname;

  @override
  MenuWidgetState createState() => MenuWidgetState();
}

class MenuWidgetState extends State<MenuWidget> {
  final moneroIcon = Image.asset('assets/images/monero_menu.png');
  final bitcoinIcon = Image.asset('assets/images/bitcoin_menu.png');
  final largeScreen = 731;

  double menuWidth;
  double screenWidth;
  double screenHeight;
  double opacity;

  double headerHeight;
  double tileHeight;
  double fromTopEdge;
  double fromBottomEdge;

  @override
  void initState() {
    menuWidth = 0;
    screenWidth = 0;
    screenHeight = 0;
    opacity = 0;

    headerHeight = 125;
    tileHeight = 75;
    fromTopEdge = 50;
    fromBottomEdge = 21;

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    setState(() {
      menuWidth = screenWidth;
      opacity = 1;

      if (screenHeight > largeScreen) {
        final scale = screenHeight / largeScreen;
        tileHeight *= scale;
        headerHeight *= scale;
        fromTopEdge *= scale;
        fromBottomEdge *= scale;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletMenu = WalletMenu(context);
    final itemCount = walletMenu.items.length;

    return SafeArea(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 24),
            child: Container(
              height: 60,
              width: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                color: PaletteDark.gray),
            )),
          SizedBox(width: 12),
          Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24)),
                child: Container(
                  width: menuWidth,
                  height: double.infinity,
                  color: Theme.of(context).textTheme.body2.decorationColor,
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: headerHeight,
                          color: Theme.of(context).textTheme.body2.color,
                          padding: EdgeInsets.only(
                              left: 24,
                              top: fromTopEdge,
                              right: 24,
                              bottom: fromBottomEdge),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              _iconFor(type: widget.type),
                              SizedBox(width: 12),
                              Expanded(
                                  child: Container(
                                    height: 42,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: widget.subname != null
                                          ? MainAxisAlignment.spaceBetween
                                          : MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          widget.name,
                                          style: TextStyle(
                                              color: Theme.of(context).textTheme
                                                  .display2.color,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (widget.subname != null)
                                          Text(
                                            widget.subname,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryTextTheme
                                                    .caption.color,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12),
                                          )
                                      ],
                                    ),
                                  ))
                            ],
                          ),
                        ),
                        Container(
                          height: 1,
                          color: Theme.of(context).primaryTextTheme.caption.decorationColor,
                        ),
                        ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (_, index) {

                              final item = walletMenu.items[index];
                              final image = walletMenu.images[index] ?? Offstage();
                              final isLastTile = index == itemCount - 1;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  walletMenu.action(index);
                                },
                                child: Container(
                                  height: isLastTile
                                          ? headerHeight
                                          : tileHeight,
                                  padding: isLastTile
                                           ? EdgeInsets.only(
                                               left: 24,
                                               right: 24,
                                               top: fromBottomEdge,
                                               bottom: fromTopEdge)
                                           : EdgeInsets.only(left: 24, right: 24),
                                  alignment: isLastTile ? Alignment.topLeft : null,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      image,
                                      SizedBox(width: 16),
                                      Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                                color: Theme.of(context).textTheme
                                                    .display2.color,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ))
                                    ],
                                  ),
                                )
                              );
                            },
                            separatorBuilder: (_, index) => Container(
                              height: 1,
                              color: Theme.of(context).primaryTextTheme.caption.decorationColor,
                            ),
                            itemCount: itemCount)
                      ],
                    ),
                  ),
                ),
              )
          )
        ],
      )
    );
  }

  Image _iconFor({@required WalletType type}) {
    switch (type) {
      case WalletType.monero:
        return moneroIcon;
      case WalletType.bitcoin:
        return bitcoinIcon;
      default:
        return null;
    }
  }
}
