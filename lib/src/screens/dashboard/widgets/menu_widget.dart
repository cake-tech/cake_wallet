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
  double menuWidth;
  double screenWidth;
  double opacity;
  bool isDraw;

  @override
  void initState() {
    menuWidth = 0;
    screenWidth = 0;
    opacity = 0;
    isDraw = false;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      menuWidth = screenWidth;
      opacity = 1;
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
            child: Padding(
              padding: EdgeInsets.only(left: 40),
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
                              height: 144,
                              padding: EdgeInsets.only(left: 24, top: 69, right: 24, bottom: 35),
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
                              height: 144,
                              padding: EdgeInsets.only(left: 24, right: 24, top: 35, bottom: 69),
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
                              height: 91,
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
            ),
          ),
        ),
      ),
    );
  }
}