import 'dart:ui';
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
  final moneroIcon = Image.asset('assets/images/monero.png');
  final bitcoinIcon = Image.asset('assets/images/bitcoin.png');
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

    headerHeight = 120;
    tileHeight = 75;
    fromTopEdge = 50;
    fromBottomEdge = 30;

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
//    final walletStore = Provider.of<WalletStore>(context);
    final itemCount = walletMenu.items.length;

    return Row(
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
                  color: Theme.of(context).hintColor),
            )),
        SizedBox(width: 12),
        Expanded(
            child: GestureDetector(
          onTap: () => null,
          child: Container(
            width: menuWidth,
            height: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24)),
                color: Theme.of(context).primaryTextTheme.display1.color),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24)),
              child: ListView.separated(
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return Container(
                        height: headerHeight,
                        padding: EdgeInsets.only(
                            left: 24,
                            top: fromTopEdge,
                            right: 24,
                            bottom: fromBottomEdge),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.only(topLeft: Radius.circular(24)),
                            color: Theme.of(context)
                                .primaryTextTheme
                                .display2
                                .color),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            _iconFor(type: widget.type),
                            SizedBox(width: 16),
                            Expanded(
                                child: Container(
                              height: 40,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: widget.subname != null
                                    ? MainAxisAlignment.spaceBetween
                                    : MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    widget.name,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .color,
                                        decoration: TextDecoration.none,
                                        fontFamily: 'Avenir Next',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (widget.subname != null)
                                    Text(
                                      widget.subname,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .primaryTextTheme
                                              .caption
                                              .color,
                                          decoration: TextDecoration.none,
                                          fontFamily: 'Avenir Next',
                                          fontSize: 12),
                                    )
                                ],
                              ),
                            ))
                          ],
                        ),
                      );
                    }

                    index -= 1;
                    final item = walletMenu.items[index];
                    final image = walletMenu.images[index] ?? Offstage();

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        walletMenu.action(index);
                      },
                      child: index == itemCount - 1
                          ? Container(
                              height: headerHeight,
                              padding: EdgeInsets.only(
                                  left: 24,
                                  right: 24,
                                  top: fromBottomEdge,
                                  bottom: fromTopEdge),
                              alignment: Alignment.topLeft,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(24)),
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .display1
                                    .color,
                              ),
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
                                        decoration: TextDecoration.none,
                                        color: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .color,
                                        fontFamily: 'Avenir Next',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ))
                                ],
                              ),
                            )
                          : Container(
                              height: tileHeight,
                              padding: EdgeInsets.only(left: 24, right: 24),
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .display1
                                  .color,
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
                                        decoration: TextDecoration.none,
                                        color: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .color,
                                        fontFamily: 'Avenir Next',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ))
                                ],
                              ),
                            ),
                    );
                  },
                  separatorBuilder: (_, index) => Container(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                  itemCount: itemCount + 1),
            ),
          ),
        ))
      ],
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
