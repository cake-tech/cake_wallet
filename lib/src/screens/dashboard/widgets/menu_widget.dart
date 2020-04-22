import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/dashboard/wallet_menu.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:provider/provider.dart';

class MenuWidget extends StatefulWidget {
  @override
  MenuWidgetState createState() => MenuWidgetState();
}

class MenuWidgetState extends State<MenuWidget> {
  final moneroIcon = Image.asset('assets/images/monero.png');
  final largeScreen = 731;

  double menuWidth;
  double screenWidth;
  double screenHeight;
  double opacity;
  bool isDraw;

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
    isDraw = false;

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

    Timer(Duration(milliseconds: 350), () =>
        setState(() => isDraw = true)
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletMenu = WalletMenu(context);
    final walletStore = Provider.of<WalletStore>(context);
    final itemCount = walletMenu.items.length;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration: BoxDecoration(color: PaletteDark.historyPanel.withOpacity(0.75)),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 24),
                  child: isDraw
                    ? Container(
                    height: 60,
                    width: 4,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                        color: PaletteDark.walletCardText
                    ),
                  )
                  : Container(
                    height: 60,
                    width: 4,
                  )
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => null,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.centerRight,
                      child: AnimatedContainer(
                          alignment: Alignment.centerLeft,
                          width: menuWidth,
                          height: double.infinity,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.fastOutSlowIn,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
                              color: PaletteDark.menuList.withOpacity(opacity)
                          ),
                          child: isDraw
                              ? ListView.separated(
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
                                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
                                        color: PaletteDark.menuHeader
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: <Widget>[
                                        moneroIcon,
                                        SizedBox(width: 16),
                                        Expanded(
                                            child: Container(
                                              height: 40,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    walletStore.name,
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        decoration: TextDecoration.none,
                                                        fontFamily: 'Lato',
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                  Text(
                                                    walletStore.account.label,
                                                    style: TextStyle(
                                                        color: PaletteDark.walletCardText,
                                                        decoration: TextDecoration.none,
                                                        fontFamily: 'Lato',
                                                        fontSize: 12
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )
                                        )
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
                                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
                                      color: PaletteDark.menuList,
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
                                                  color: Colors.white,
                                                  fontFamily: 'Lato',
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            )
                                        )
                                      ],
                                    ),
                                  )
                                      : Container(
                                    height: tileHeight,
                                    padding: EdgeInsets.only(left: 24, right: 24),
                                    color: PaletteDark.menuList,
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
                                                  color: Colors.white,
                                                  fontFamily: 'Lato',
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            )
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (_, index) =>
                                  Divider(
                                    height: 1,
                                    color: PaletteDark.walletCardText,
                                  ),
                              itemCount: itemCount + 1)
                              : Offstage()
                      ),
                    ),
                  )
                )
              ],
            )
          ),
        ),
      ),
    );
  }
}