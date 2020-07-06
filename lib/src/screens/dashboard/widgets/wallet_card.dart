import 'dart:async';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard_view_model.dart';

class WalletCard extends StatefulWidget {
  WalletCard({this.walletVM});

  final DashboardViewModel walletVM;

  @override
  WalletCardState createState() => WalletCardState();
}

class WalletCardState extends State<WalletCard> {
  final _syncingObserverKey = GlobalKey();
  final _balanceObserverKey = GlobalKey();
  final _addressObserverKey = GlobalKey();

  double cardWidth;
  double cardHeight;
  double screenWidth;
  double opacity;
  bool isDraw;
  bool isFrontSide;

  @override
  void initState() {
    cardWidth = 0;
    cardHeight = 220;
    screenWidth = 0;
    opacity = 0;
    isDraw = false;
    isFrontSide = true;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    screenWidth = MediaQuery.of(context).size.width - 20;
    setState(() {
      cardWidth = screenWidth;
      opacity = 1;
    });
    Timer(Duration(milliseconds: 500), () => setState(() => isDraw = true));
  }

  @override
  Widget build(BuildContext context) {
    final colorsSync = [
      Theme.of(context).cardTheme.color,
      Theme.of(context).hoverColor
    ];

    return Container(
      width: double.infinity,
      height: cardHeight,
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14), bottomLeft: Radius.circular(14))),
      child: AnimatedContainer(
          alignment: Alignment.centerLeft,
          width: cardWidth,
          height: cardHeight,
          duration: Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14)),
              color: Theme.of(context).focusColor),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              color: Theme.of(context).cardColor,
              child: isFrontSide
                  ? frontSide(colorsSync)
                  : InkWell(
                      onTap: () => setState(() => isFrontSide = true),
                      child: backSide(colorsSync)),
            ),
          )),
    );
  }

  Widget frontSide(List<Color> colorsSync) {
    final settingsStore = Provider.of<SettingsStore>(context);
    final triangleButton = Image.asset(
      'assets/images/triangle.png',
      color: Theme.of(context).primaryTextTheme.title.color,
    );

    return Observer(
      key: _syncingObserverKey,
      builder: (_) {
        final status = widget.walletVM.status;
        final statusText = status.title();
        final progress = status.progress();
        final indicatorOffset = progress * cardWidth;
        final indicatorWidth =
            progress <= 1 ? cardWidth - indicatorOffset : 0.0;
        var descriptionText = '';

        if (status is SyncingSyncStatus) {
          descriptionText = S.of(context).Blocks_remaining(status.toString());
        }

        if (status is FailedSyncStatus) {
          descriptionText = S.of(context).please_try_to_connect_to_another_node;
        }

        return Container(
          width: cardWidth,
          height: cardHeight,
          color: Colors.white,
          child: Stack(
            children: <Widget>[
              progress <= 1
                  ? Positioned(
                      left: indicatorOffset,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: indicatorWidth,
                        height: cardHeight,
                        color: Color.fromRGBO(227, 238, 249, 1),
                      ))
                  : Offstage(),
              isDraw
                  ? Positioned(
                      left: 24,
                      right: 24,
                      top: 32,
                      bottom: 24,
                      child: Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    InkWell(
                                      onTap: () => Navigator.of(context)
                                          .pushNamed(Routes.walletList),
                                      child: Row(
                                        children: <Widget>[
                                          Text(
                                            widget.walletVM.name,
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .primaryTextTheme
                                                    .title
                                                    .color),
                                          ),
                                          SizedBox(width: 10),
                                          triangleButton
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    if (widget.walletVM.subname?.isNotEmpty ??
                                        false)
                                      Text(
                                        widget.walletVM.subname,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .primaryTextTheme
                                                .caption
                                                .color),
                                      )
                                  ],
                                ),
                                InkWell(
                                  onTap: () =>
                                      setState(() => isFrontSide = false),
                                  child: Container(
                                      width: 98,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .accentTextTheme
                                              .subtitle
                                              .backgroundColor,
                                          border: Border.all(
                                              color: Color.fromRGBO(
                                                  219, 231, 237, 1)),
                                          // FIXME
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(16))),
                                      child: Text(
                                        'Receive',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .primaryTextTheme
                                                .title
                                                .color),
                                      )),
                                )
                              ],
                            ),
                            status is SyncedSyncStatus
                                ? Observer(
                                    key: _balanceObserverKey,
                                    builder: (_) {
                                      final balanceDisplayMode =
                                          BalanceDisplayMode.availableBalance;
//                                          settingsStore.balanceDisplayMode;
                                      final symbol =
                                          settingsStore.fiatCurrency.toString();
                                      var balance = '---';
                                      var fiatBalance = '---';

                                      if (balanceDisplayMode ==
                                          BalanceDisplayMode.availableBalance) {
                                        balance = widget.walletVM.balance
                                                .unlockedBalance ??
                                            '0.0';
                                        fiatBalance = '\$ 0.00';
//                                            '$symbol ${balanceStore.fiatUnlockedBalance}';
                                      }

                                      if (balanceDisplayMode ==
                                          BalanceDisplayMode.fullBalance) {
                                        balance = widget.walletVM.balance
                                                .totalBalance ??
                                            '0.0';
                                        fiatBalance = '\$ 0.00';
//                                            '$symbol ${balanceStore.fiatFullBalance}';
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                balanceDisplayMode.toString(),
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .primaryTextTheme
                                                        .caption
                                                        .color),
                                              ),
                                              SizedBox(height: 5),
                                              Container(
                                                  height: 36,
                                                  child: Text(
                                                    balance,
                                                    style: TextStyle(
                                                        fontSize: 32,
                                                        color: Theme.of(context)
                                                            .primaryTextTheme
                                                            .title
                                                            .color,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ))
                                            ],
                                          ),
                                          Text(
                                            fiatBalance,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
//                                                FIXME
//                                                color: Theme.of(context)
//                                                    .primaryTextTheme
//                                                    .title
//                                                    .color,
                                                color: Color.fromRGBO(
                                                    72, 89, 109, 1)),
                                          )
                                        ],
                                      );
                                    })
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            statusText,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .primaryTextTheme
                                                    .caption
                                                    .color),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            descriptionText,
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .primaryTextTheme
                                                    .title
                                                    .color),
                                          )
                                        ],
                                      )
                                    ],
                                  )
                          ],
                        ),
                      ))
                  : Offstage()
            ],
          ),
        );
      },
    );
  }

  Widget backSide(List<Color> colorsSync) {
    final rightArrow = Image.asset('assets/images/right_arrow.png',
        color: Theme.of(context).primaryTextTheme.title.color);
    var messageBoxHeight = 0.0;
    var messageBoxWidth = cardWidth - 10;

    return Observer(
        key: _addressObserverKey,
        builder: (_) {
          return Container(
            width: cardWidth,
            height: cardHeight,
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.topRight,
              children: <Widget>[
                Container(
                  width: cardWidth,
                  height: cardHeight,
                  padding:
                      EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 32),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10)),
                      gradient: LinearGradient(
                          colors: colorsSync,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                              child: Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  S.current.card_address,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .caption
                                          .color),
                                ),
                                SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: widget.walletVM.address));
                                    _addressObserverKey.currentState
                                        .setState(() {
                                      messageBoxHeight = 20;
                                      messageBoxWidth = cardWidth;
                                    });
                                    Timer(Duration(milliseconds: 1000), () {
                                      try {
                                        _addressObserverKey.currentState
                                            .setState(() {
                                          messageBoxHeight = 0;
                                          messageBoxWidth = cardWidth - 10;
                                        });
                                      } catch (e) {
                                        print('${e.toString()}');
                                      }
                                    });
                                  },
                                  child: Text(
                                    widget.walletVM.address,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .color),
                                  ),
                                )
                              ],
                            ),
                          )),
                          SizedBox(width: 10),
                          Container(
                            width: 90,
                            height: 90,
                            child: QrImage(
                                data: widget.walletVM.address,
                                backgroundColor: Colors.transparent,
                                foregroundColor: Theme.of(context)
                                    .primaryTextTheme
                                    .caption
                                    .color),
                          )
                        ],
                      ),
                      Container(
                        height: 44,
                        padding: EdgeInsets.only(left: 20, right: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(22)),
                            color: Theme.of(context)
                                .primaryTextTheme
                                .overline
                                .color),
                        child: InkWell(
                          onTap: () =>
                              Navigator.of(context, rootNavigator: true)
                                  .pushNamed(Routes.receive),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                S.of(context).addresses,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .primaryTextTheme
                                        .title
                                        .color),
                              ),
                              rightArrow
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                AnimatedContainer(
                  width: messageBoxWidth,
                  height: messageBoxHeight,
                  alignment: Alignment.center,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.fastOutSlowIn,
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.only(topLeft: Radius.circular(10)),
                      color: Colors.green),
                  child: Text(
                    S.of(context).copied_to_clipboard,
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                )
              ],
            ),
          );
        });
  }
}
