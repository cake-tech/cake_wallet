import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/src/screens/dashboard/wallet_menu.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

// FIXME: terrible design.

class MenuWidget extends StatefulWidget {
  MenuWidget(this.dashboardViewModel);

  final DashboardViewModel dashboardViewModel;

  @override
  MenuWidgetState createState() => MenuWidgetState();
}

class MenuWidgetState extends State<MenuWidget> {
  Image moneroIcon;
  Image bitcoinIcon;
  Image litecoinIcon;
  Image havenIcon;
  final largeScreen = 731;

  double menuWidth;
  double screenWidth;
  double screenHeight;

  double headerHeight;
  double tileHeight;
  double fromTopEdge;
  double fromBottomEdge;

  @override
  void initState() {
    menuWidth = 0;
    screenWidth = 0;
    screenHeight = 0;

    headerHeight = 120;
    tileHeight = 60;
    fromTopEdge = 50;
    fromBottomEdge = 25;

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    setState(() {
      menuWidth = screenWidth;

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
    final walletMenu = WalletMenu(
        context,
        () async => widget.dashboardViewModel.reconnect(),
        widget.dashboardViewModel.hasRescan);
    final itemCount = walletMenu.items.length;

    moneroIcon = Image.asset('assets/images/monero_menu.png',
        color: Theme.of(context).accentTextTheme.overline.decorationColor);
    bitcoinIcon = Image.asset('assets/images/bitcoin_menu.png',
        color: Theme.of(context).accentTextTheme.overline.decorationColor);
    litecoinIcon = Image.asset('assets/images/litecoin_menu.png');
    havenIcon = Image.asset('assets/images/haven_menu.png');

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
                  color: PaletteDark.gray),
            )),
        SizedBox(width: 12),
        Expanded(
            child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24)),
                child: Container(
                  color: Theme.of(context).textTheme.body2.decorationColor,
                  child: ListView.separated(
                      padding: EdgeInsets.only(top: 0),
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          return Container(
                            height: headerHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context)
                                        .accentTextTheme
                                        .display1
                                        .color,
                                    Theme.of(context)
                                        .accentTextTheme
                                        .display1
                                        .decorationColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                            ),
                            padding: EdgeInsets.only(
                                left: 24,
                                top: fromTopEdge,
                                right: 24,
                                bottom: fromBottomEdge),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                _iconFor(type: widget.dashboardViewModel.type),
                                SizedBox(width: 12),
                                SingleChildScrollView(
                                    child: Container(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        widget.dashboardViewModel.subname !=
                                                null
                                            ? MainAxisAlignment.spaceBetween
                                            : MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        widget.dashboardViewModel.name,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (widget.dashboardViewModel.subname !=
                                          null)
                                        Observer(
                                            builder: (_) => Text(
                                                  widget.dashboardViewModel
                                                      .subname,
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .accentTextTheme
                                                          .overline
                                                          .decorationColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 12),
                                                ))
                                    ],
                                  ),
                                ))
                              ],
                            ),
                          );
                        }

                        index--;

                        final item = walletMenu.items[index];
                        final title = item.title;
                        final image = item.image ?? Offstage();
                        final isLastTile = index == itemCount - 1;

                        return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              walletMenu.action(index);
                            },
                            child: Container(
                              color: Theme.of(context)
                                  .textTheme
                                  .body2
                                  .decorationColor,
                              height: isLastTile ? headerHeight : tileHeight,
                              padding: isLastTile
                                  ? EdgeInsets.only(
                                      left: 24,
                                      right: 24,
                                      top: fromBottomEdge,
                                      //bottom: fromTopEdge
                                    )
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
                                    title,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .display2
                                            .color,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ))
                                ],
                              ),
                            ));
                      },
                      separatorBuilder: (_, index) => Container(
                            height: 1,
                            color: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .decorationColor,
                          ),
                      itemCount: itemCount + 1),
                )))
      ],
    );
  }

  Image _iconFor({@required WalletType type}) {
    switch (type) {
      case WalletType.monero:
        return moneroIcon;
      case WalletType.bitcoin:
        return bitcoinIcon;
      case WalletType.litecoin:
        return litecoinIcon;
      case WalletType.haven:
        return havenIcon;
      default:
        return null;
    }
  }
}
