import 'dart:async';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/src/stores/balance/balance_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/sync/sync_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/routes.dart';

class WalletCard extends StatefulWidget {
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
    Timer(Duration(milliseconds: 500), () =>
        setState(() => isDraw = true)
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colorsSync = [
      Theme.of(context).cardTheme.color,
      Theme.of(context).hoverColor
    ];

    return Container(
      width: double.infinity,
      height: cardHeight,
      alignment: Alignment.centerRight,
      child: AnimatedContainer(
        alignment: Alignment.centerLeft,
        width: cardWidth,
        height: cardHeight,
        duration: Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        padding: EdgeInsets.only(
          top: 1,
          left: 1,
          bottom: 1
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
          color: Theme.of(context).focusColor,
          boxShadow: [
            BoxShadow(
              color: PaletteDark.darkNightBlue.withOpacity(0.5),
              blurRadius: 8,
              offset: Offset(5, 5))
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            color: Theme.of(context).cardColor,
            child: InkWell(
                onTap: () => setState(() => isFrontSide = !isFrontSide),
                child: isFrontSide
                    ? frontSide(colorsSync)
                    : backSide(colorsSync)
            ),
          ),
        )
      ),
    );
  }

  Widget frontSide(List<Color> colorsSync) {
    final syncStore = Provider.of<SyncStore>(context);
    final walletStore = Provider.of<WalletStore>(context);
    final settingsStore = Provider.of<SettingsStore>(context);
    final balanceStore = Provider.of<BalanceStore>(context);
    final triangleButton = Image.asset('assets/images/triangle.png',
      color: Theme.of(context).primaryTextTheme.title.color,
    );

    return Observer(
      key: _syncingObserverKey,
      builder: (_) {
        final status = syncStore.status;
        final statusText = status.title();
        final progress = syncStore.status.progress();
        final indicatorWidth = progress * cardWidth;

        String shortAddress = walletStore.subaddress.address;
        shortAddress = shortAddress.replaceRange(4, shortAddress.length - 4, '...');

        var descriptionText = '';

        if (status is SyncingSyncStatus) {
          descriptionText = S
              .of(context)
              .Blocks_remaining(
              syncStore.status.toString());
        }

        if (status is FailedSyncStatus) {
          descriptionText = S
              .of(context)
              .please_try_to_connect_to_another_node;
        }

        return Container(
          width: cardWidth,
          height: cardHeight,
          child: Stack(
            children: <Widget>[
              Container(
                height: cardHeight,
                width: indicatorWidth,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                    gradient: LinearGradient(
                        colors: colorsSync,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter
                    )
                ),
              ),
              progress != 1
              ? Positioned(
                  left: indicatorWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    height: cardHeight,
                    color: Theme.of(context).focusColor,
                  )
              )
              : Offstage(),
              isDraw ? Positioned(
                  left: 20,
                  right: 20,
                  top: 30,
                  bottom: 30,
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
                                  onTap: () {},
                                  child: Row(
                                    children: <Widget>[
                                      Text(
                                        walletStore.name,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryTextTheme.title.color
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      triangleButton
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  walletStore.account.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryTextTheme.caption.color
                                  ),
                                )
                              ],
                            ),
                            Container(
                              width: 98,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).accentTextTheme.subtitle.backgroundColor,
                                  borderRadius: BorderRadius.all(Radius.circular(16))
                              ),
                              child: Text(
                                shortAddress,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryTextTheme.caption.color
                                ),
                              ),
                            )
                          ],
                        ),
                        status is SyncedSyncStatus
                            ? Observer(
                            key: _balanceObserverKey,
                            builder: (_) {
                              final balanceDisplayMode = settingsStore.balanceDisplayMode;
                              final symbol = settingsStore
                                  .fiatCurrency
                                  .toString();
                              var balance = '---';
                              var fiatBalance = '---';

                              if (balanceDisplayMode ==
                                  BalanceDisplayMode.availableBalance) {
                                balance =
                                    balanceStore.unlockedBalance ??
                                        '0.0';
                                fiatBalance =
                                '$symbol ${balanceStore.fiatUnlockedBalance}';
                              }

                              if (balanceDisplayMode ==
                                  BalanceDisplayMode.fullBalance) {
                                balance =
                                    balanceStore.fullBalance ?? '0.0';
                                fiatBalance =
                                '$symbol ${balanceStore.fiatFullBalance}';
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        balanceDisplayMode.toString(),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).primaryTextTheme.caption.color
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        balance,
                                        style: TextStyle(
                                            fontSize: 28,
                                            height: 1,
                                            color: Theme.of(context).primaryTextTheme.title.color
                                        ),
                                      )
                                    ],
                                  ),
                                  Text(
                                    fiatBalance,
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 2,
                                        color: Theme.of(context).primaryTextTheme.title.color
                                    ),
                                  )
                                ],
                              );
                            }
                          )
                          : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  statusText,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryTextTheme.caption.color
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  descriptionText,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).primaryTextTheme.title.color
                                  ),
                                )
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  )
              )
              : Offstage()
            ],
          ),
        );
      },
    );
  }

  Widget backSide(List<Color> colorsSync) {
    final walletStore = Provider.of<WalletStore>(context);
    final rightArrow = Image.asset('assets/images/right_arrow.png',
      color: Theme.of(context).primaryTextTheme.title.color,
    );
    double messageBoxHeight = 0;
    double messageBoxWidth = cardWidth - 10;

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
                padding: EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 30),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                    gradient: LinearGradient(
                        colors: colorsSync,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter
                    )
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 90,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  S.current.card_address,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryTextTheme.caption.color
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: walletStore.subaddress.address));
                                    _addressObserverKey.currentState.setState(() {
                                      messageBoxHeight = 20;
                                      messageBoxWidth = cardWidth;
                                    });
                                    Timer(Duration(milliseconds: 1000), () {
                                      try {
                                        _addressObserverKey.currentState.setState(() {
                                          messageBoxHeight = 0;
                                          messageBoxWidth = cardWidth;
                                        });
                                      } catch(e) {
                                        print('${e.toString()}');
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Text(
                                      walletStore.subaddress.address,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).primaryTextTheme.title.color
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 90,
                          height: 90,
                          child: QrImage(
                            data: walletStore.subaddress.address,
                            backgroundColor: Colors.transparent,
                            foregroundColor: Theme.of(context).primaryTextTheme.caption.color
                          ),
                        )
                      ],
                    ),
                    Container(
                      height: 44,
                      padding: EdgeInsets.only(left: 20, right: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                          color: Theme.of(context).primaryTextTheme.overline.color
                      ),
                      child: InkWell(
                        onTap: () => Navigator.of(context,
                            rootNavigator: true)
                            .pushNamed(Routes.receive),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              S.of(context).accounts_subaddresses,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).primaryTextTheme.title.color
                              ),
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
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
                    color: Colors.green
                ),
                child: Text(
                  S.of(context).copied_to_clipboard,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white
                  ),
                ),
              )
            ],
          ),
        );
      }
    );
  }
}