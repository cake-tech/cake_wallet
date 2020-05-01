import 'dart:async';
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
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/screens/receive/qr_image.dart';

class WalletCard extends StatefulWidget {
  @override
  WalletCardState createState() => WalletCardState();
}

class WalletCardState extends State<WalletCard> {
  final _syncingObserverKey = GlobalKey();
  final _balanceObserverKey = GlobalKey();
  final _addressObserverKey = GlobalKey();

  final List<Color> colorsSync = [PaletteDark.walletCardSubAddressField, PaletteDark.walletCardBottomEndSync];
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
          color: PaletteDark.borderCardColor,
          boxShadow: [
            BoxShadow(
              color: PaletteDark.historyPanel.withOpacity(0.5),
              blurRadius: 8,
              offset: Offset(5, 5))
          ]
        ),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
              color: PaletteDark.historyPanel
          ),
          child: InkWell(
              onTap: () => setState(() => isFrontSide = !isFrontSide),
              child: isFrontSide
                  ? frontSide()
                  : backSide()
          ),
        ),
      ),
    );
  }

  Widget frontSide() {
    final syncStore = Provider.of<SyncStore>(context);
    final walletStore = Provider.of<WalletStore>(context);
    final settingsStore = Provider.of<SettingsStore>(context);
    final balanceStore = Provider.of<BalanceStore>(context);
    final triangleButton = Image.asset('assets/images/triangle.png');

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
                    color: PaletteDark.borderCardColor,
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
                                  onTap: () {print('TAP 2');},
                                  child: Row(
                                    children: <Widget>[
                                      Text(
                                        walletStore.name,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white
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
                                      color: PaletteDark.walletCardText
                                  ),
                                )
                              ],
                            ),
                            Container(
                              width: 98,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: PaletteDark.walletCardAddressField,
                                  borderRadius: BorderRadius.all(Radius.circular(16))
                              ),
                              child: Text(
                                shortAddress,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: PaletteDark.walletCardAddressText
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
                                            color: PaletteDark.walletCardText
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        balance,
                                        style: TextStyle(
                                            fontSize: 28,
                                            color: Colors.white
                                        ),
                                      )
                                    ],
                                  ),
                                  Text(
                                    fiatBalance,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white
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
                                      color: PaletteDark.walletCardText
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  descriptionText,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white
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

  Widget backSide() {
    final walletStore = Provider.of<WalletStore>(context);
    final rightArrow = Image.asset('assets/images/right_arrow.png');
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
                            height: 84,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  S.current.card_address,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: PaletteDark.walletCardText
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
                                          messageBoxWidth = cardWidth - 10;
                                        });
                                      } catch(e) {
                                        print('${e.toString()}');
                                      }
                                    });
                                  },
                                  child: Text(
                                    walletStore.subaddress.address,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 84,
                          height: 84,
                          child: QrImage(
                            data: walletStore.subaddress.address,
                            backgroundColor: Colors.transparent,
                            foregroundColor: PaletteDark.walletCardText,
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
                          color: PaletteDark.walletCardSubAddressField
                      ),
                      child: InkWell(
                        onTap: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              S.current.subaddresses,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white
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